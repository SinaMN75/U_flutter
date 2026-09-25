import "package:u/utilities.dart";

// =============================================================================
// Download UI: a full IDM-style manager page, a list tile with a per-segment
// progress bar, a one-tap download button, and the add / settings sheets.
// Every widget listens to UDownloadManager / UDownloadTask directly, so they
// stay live without any state management of their own.
// =============================================================================

String uFormatBytes(int bytes) {
  if (bytes < 0) return "—";
  const List<String> units = <String>["B", "KB", "MB", "GB", "TB"];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return "${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}";
}

String _formatDuration(Duration d) {
  if (d.inHours > 0) return "${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, "0")}:${(d.inSeconds % 60).toString().padLeft(2, "0")}";
  return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, "0")}";
}

String uDownloadStatusLabel(UDownloadTask task) => switch (task.status) {
  UDownloadStatus.queued => U.s.downloadQueued,
  UDownloadStatus.scheduled => U.s.downloadScheduled,
  UDownloadStatus.waitingForNetwork => task.request.wifiOnly ? U.s.waitingForWifi : U.s.waitingForNetwork,
  UDownloadStatus.connecting => U.s.connecting,
  UDownloadStatus.downloading => U.s.downloading,
  UDownloadStatus.paused => U.s.paused,
  UDownloadStatus.verifying => U.s.verifying,
  UDownloadStatus.completed => U.s.completed,
  UDownloadStatus.failed => uDownloadErrorLabel(task.error),
  UDownloadStatus.canceled => U.s.cancelled,
};

String uDownloadErrorLabel(UDownloadError? error) => switch (error?.code) {
  UDownloadErrorCode.network => U.s.downloadErrorNetwork,
  UDownloadErrorCode.timeout => U.s.downloadErrorTimeout,
  UDownloadErrorCode.http => "${U.s.downloadErrorHttp} (${error?.statusCode})",
  UDownloadErrorCode.unauthorized => U.s.downloadErrorUnauthorized,
  UDownloadErrorCode.forbidden => U.s.downloadErrorForbidden,
  UDownloadErrorCode.notFound => U.s.downloadErrorNotFound,
  UDownloadErrorCode.serverError => U.s.downloadErrorServer,
  UDownloadErrorCode.fileChanged => U.s.downloadErrorFileChanged,
  UDownloadErrorCode.checksumMismatch => U.s.downloadErrorChecksum,
  UDownloadErrorCode.insufficientSpace => U.s.downloadErrorSpace,
  UDownloadErrorCode.storage => U.s.downloadErrorStorage,
  UDownloadErrorCode.certificate => U.s.downloadErrorCertificate,
  UDownloadErrorCode.unsupported => U.s.downloadErrorUnsupported,
  _ => U.s.downloadErrorUnknown,
};

IconData uDownloadCategoryIcon(UDownloadCategory category) => switch (category) {
  UDownloadCategory.document => Icons.description_outlined,
  UDownloadCategory.image => Icons.image_outlined,
  UDownloadCategory.audio => Icons.audiotrack_outlined,
  UDownloadCategory.video => Icons.movie_outlined,
  UDownloadCategory.archive => Icons.folder_zip_outlined,
  UDownloadCategory.program => Icons.apps_outlined,
  UDownloadCategory.other => Icons.insert_drive_file_outlined,
};

String _categoryLabel(UDownloadCategory category) => switch (category) {
  UDownloadCategory.document => U.s.documents,
  UDownloadCategory.image => U.s.images,
  UDownloadCategory.audio => U.s.audio,
  UDownloadCategory.video => U.s.videos,
  UDownloadCategory.archive => U.s.archives,
  UDownloadCategory.program => U.s.programs,
  UDownloadCategory.other => U.s.other,
};

enum _Filter { all, active, completed, failed }

/// Full-screen download manager: filters, categories, live speed, bulk actions and settings.
class UDownloadManagerPage extends StatefulWidget {
  const UDownloadManagerPage({super.key, this.manager, this.allowAdd = true, this.title});

  final UDownloadManager? manager;

  /// Shows the "add download" action for pasting a URL.
  final bool allowAdd;
  final String? title;

  @override
  State<UDownloadManagerPage> createState() => _UDownloadManagerPageState();
}

class _UDownloadManagerPageState extends State<UDownloadManagerPage> {
  _Filter _filter = _Filter.all;
  UDownloadCategory? _category;

  UDownloadManager get _manager => widget.manager ?? UDownloadManager.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_manager.init());
  }

  List<UDownloadTask> _visible(List<UDownloadTask> tasks) => tasks.where((UDownloadTask t) {
    final bool byStatus = switch (_filter) {
      _Filter.all => true,
      _Filter.active => !t.isFinished,
      _Filter.completed => t.status == UDownloadStatus.completed,
      _Filter.failed => t.status == UDownloadStatus.failed || t.status == UDownloadStatus.canceled,
    };
    return byStatus && (_category == null || t.category == _category);
  }).toList();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _manager,
      builder: (BuildContext context, Widget? child) {
        final List<UDownloadTask> tasks = _manager.tasks;
        final List<UDownloadTask> shown = _visible(tasks);
        final bool anyActive = tasks.any((UDownloadTask t) => t.canPause);
        final bool anyPaused = tasks.any((UDownloadTask t) => t.canResume);
        return UScaffold(
          appBar: AppBar(
            title: UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UTextTitleLarge(widget.title ?? U.s.downloads, fontWeight: FontWeight.bold),
                if (_manager.totalSpeed > 0) UTextBodySmall("${uFormatBytes(_manager.totalSpeed.round())}/s", color: cs.primary),
              ],
            ),
            actions: <Widget>[
              if (widget.allowAdd) IconButton(tooltip: U.s.addDownload, onPressed: () => unawaited(UAddDownloadSheet.show(manager: _manager)), icon: const Icon(Icons.add_link_rounded)),
              PopupMenuButton<String>(
                onSelected: (String value) => unawaited(switch (value) {
                  "pause" => _manager.pauseAll(),
                  "resume" => _manager.resumeAll(),
                  "clear" => _manager.clearFinished(),
                  _ => UDownloadSettingsSheet.show(manager: _manager),
                }),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: "pause", enabled: anyActive, child: UTextBodyMedium(U.s.pauseAll)),
                  PopupMenuItem<String>(value: "resume", enabled: anyPaused, child: UTextBodyMedium(U.s.resumeAll)),
                  PopupMenuItem<String>(value: "clear", child: UTextBodyMedium(U.s.clearFinished)),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(value: "settings", child: UTextBodyMedium(U.s.settings)),
                ],
              ),
            ],
          ),
          body: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: URow(
                  spacing: 8,
                  children: <Widget>[
                    for (final _Filter filter in _Filter.values)
                      ChoiceChip(
                        label: UTextLabelMedium(switch (filter) {
                          _Filter.all => U.s.all,
                          _Filter.active => U.s.active,
                          _Filter.completed => U.s.completed,
                          _Filter.failed => U.s.failed,
                        }),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    const SizedBox(width: 8),
                    for (final UDownloadCategory category in UDownloadCategory.values)
                      if (tasks.any((UDownloadTask t) => t.category == category))
                        FilterChip(
                          avatar: Icon(uDownloadCategoryIcon(category), size: 16),
                          label: UTextLabelMedium(_categoryLabel(category)),
                          selected: _category == category,
                          onSelected: (bool on) => setState(() => _category = on ? category : null),
                        ),
                  ],
                ),
              ),
              if (shown.isEmpty)
                UEmptyState(title: U.s.noDownloads).expanded()
              else
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: shown.length,
                  separatorBuilder: (BuildContext context, int i) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int i) => UDownloadTile(task: shown[i], manager: _manager),
                ).expanded(),
            ],
          ),
        );
      },
    );
  }
}

/// One task: icon, name, status, a segment-aware progress bar, speed/ETA and actions.
class UDownloadTile extends StatelessWidget {
  const UDownloadTile({required this.task, super.key, this.manager, this.showSegments = true});

  final UDownloadTask task;
  final UDownloadManager? manager;
  final bool showSegments;

  UDownloadManager get _manager => manager ?? UDownloadManager.instance;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: task,
      builder: (BuildContext context, Widget? child) {
        final bool failed = task.status == UDownloadStatus.failed;
        final Color accent = failed ? cs.error : (task.status == UDownloadStatus.completed ? cs.tertiary : cs.primary);
        return UContainer(
          padding: const EdgeInsets.all(14),
          radius: 16,
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          child: UColumn(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              URow(
                spacing: 12,
                children: <Widget>[
                  UContainer(
                    width: 44,
                    height: 44,
                    radius: 12,
                    color: accent.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(task.request.destination.isEncrypted ? Icons.lock_outline_rounded : uDownloadCategoryIcon(task.category), color: accent, size: 22),
                  ),
                  UColumn(
                    spacing: 2,
                    expanded: 1,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UTextTitleSmall(task.displayName, fontWeight: FontWeight.w700, maxLines: 1, overflow: TextOverflow.ellipsis),
                      UTextBodySmall(_subtitle(), color: failed ? cs.error : cs.onSurfaceVariant, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  ..._actions(cs),
                ],
              ),
              if (!task.isFinished && showSegments && task.segments.length > 1 && task.total > 0)
                USegmentProgressBar(task: task, color: accent)
              else if (!task.isFinished)
                UProgressLinear(value: task.total > 0 ? (task.progress * 100).round() : null, height: 6, progressColor: accent),
            ],
          ),
        );
      },
    );
  }

  String _subtitle() {
    final String size = task.total > 0 ? "${uFormatBytes(task.received)} / ${uFormatBytes(task.total)}" : uFormatBytes(task.received);
    if (task.status == UDownloadStatus.downloading) {
      final Duration? eta = task.eta;
      return "$size · ${uFormatBytes(task.speed.round())}/s${eta == null ? "" : " · ${_formatDuration(eta)}"}";
    }
    if (task.status == UDownloadStatus.completed) return "${uFormatBytes(task.total)} · ${U.s.completed}";
    return "${uDownloadStatusLabel(task)} · $size";
  }

  List<Widget> _actions(ColorScheme cs) {
    IconButton button(IconData icon, String tooltip, VoidCallback onPressed, {Color? color}) =>
        IconButton(tooltip: tooltip, visualDensity: VisualDensity.compact, onPressed: onPressed, icon: Icon(icon, size: 20, color: color ?? cs.primary));
    if (task.status == UDownloadStatus.completed) {
      return <Widget>[
        if (task.request.destination.target != UDownloadTarget.memory) button(Icons.open_in_new_rounded, U.s.open, () => unawaited(_manager.open(task))),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
          onSelected: (String value) => unawaited(switch (value) {
            "reveal" => _manager.reveal(task),
            "share" => _manager.share(task),
            "delete" => _manager.remove(task.id, deleteFile: true),
            _ => _manager.remove(task.id),
          }),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (!UDownloadPlatform.isWeb) PopupMenuItem<String>(value: "reveal", child: UTextBodyMedium(U.s.showInFolder)),
            if (!UDownloadPlatform.isWeb) PopupMenuItem<String>(value: "share", child: UTextBodyMedium(U.s.share)),
            PopupMenuItem<String>(value: "remove", child: UTextBodyMedium(U.s.remove)),
            PopupMenuItem<String>(value: "delete", child: UTextBodyMedium(U.s.delete, color: cs.error)),
          ],
        ),
      ];
    }
    return <Widget>[
      if (task.canPause && !task.system) button(Icons.pause_rounded, U.s.pause, () => unawaited(_manager.pause(task.id))),
      if (task.status == UDownloadStatus.paused) button(Icons.play_arrow_rounded, U.s.resume, () => unawaited(_manager.resume(task.id))),
      if (task.status == UDownloadStatus.failed || task.status == UDownloadStatus.canceled)
        button(Icons.refresh_rounded, U.s.retry, () => unawaited(task.isResumable ? _manager.resume(task.id) : _manager.retry(task.id))),
      if (task.isFinished)
        button(Icons.close_rounded, U.s.delete, () => unawaited(_manager.remove(task.id)), color: cs.onSurfaceVariant)
      else
        button(Icons.close_rounded, U.s.cancel, () => unawaited(_manager.cancel(task.id)), color: cs.error),
    ];
  }
}

/// IDM's signature bar: one lane per connection, drawn at its byte offset.
class USegmentProgressBar extends StatelessWidget {
  const USegmentProgressBar({required this.task, super.key, this.height = 8, this.color});

  final UDownloadTask task;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _SegmentPainter(
            total: task.total,
            segments: task.segments.map((UDownloadSegment s) => (s.start, s.position, s.end)).toList(),
            background: cs.surfaceContainerHighest,
            filled: color ?? cs.primary,
            divider: cs.surface,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter({required this.total, required this.segments, required this.background, required this.filled, required this.divider});

  final int total;
  final List<(int, int, int)> segments;
  final Color background;
  final Color filled;
  final Color divider;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (total <= 0) return;
    final Paint fill = Paint()..color = filled;
    final Paint line = Paint()
      ..color = divider
      ..strokeWidth = 1;
    for (final (int start, int position, int end) in segments) {
      final double x0 = start / total * size.width;
      final double x1 = position / total * size.width;
      canvas.drawRect(Rect.fromLTRB(x0, 0, x1, size.height), fill);
      if (start > 0) canvas.drawLine(Offset(x0, 0), Offset(x0, size.height), line);
      if (end < total && end > 0) canvas.drawLine(Offset(end / total * size.width, 0), Offset(end / total * size.width, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) => true;
}

/// A one-tap download control: idle → progress ring (tap to pause/resume) → done (tap to open).
class UDownloadButton extends StatefulWidget {
  const UDownloadButton({
    required this.request,
    super.key,
    this.manager,
    this.size = 44,
    this.onCompleted,
  });

  final UDownloadRequest request;
  final UDownloadManager? manager;
  final double size;
  final void Function(UDownloadTask task)? onCompleted;

  @override
  State<UDownloadButton> createState() => _UDownloadButtonState();
}

class _UDownloadButtonState extends State<UDownloadButton> {
  UDownloadTask? _task;

  UDownloadManager get _manager => widget.manager ?? UDownloadManager.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_attach());
  }

  // Re-attach to an existing task for the same source after a rebuild or restart.
  Future<void> _attach() async {
    await _manager.init();
    final UDownloadTask? existing = _manager.allTasks.cast<UDownloadTask?>().lastWhere(
      (UDownloadTask? t) =>
          t!.request.url == widget.request.url &&
          t.request.sourceId == widget.request.sourceId &&
          t.status != UDownloadStatus.canceled,
      orElse: () => null,
    );
    if (mounted && existing != null) setState(() => _task = existing);
  }

  Future<void> _onTap() async {
    final UDownloadTask? task = _task;
    if (task == null || task.status == UDownloadStatus.canceled) {
      final UDownloadTask created = await _manager.enqueue(widget.request);
      if (!mounted) return;
      setState(() => _task = created);
      unawaited(created.done.then((UDownloadTask t) {
        if (t.status == UDownloadStatus.completed) widget.onCompleted?.call(t);
      }));
      return;
    }
    if (task.status == UDownloadStatus.completed) {
      await _manager.open(task);
    } else if (task.canPause) {
      await _manager.pause(task.id);
    } else if (task.status == UDownloadStatus.failed) {
      await (task.isResumable ? _manager.resume(task.id) : _manager.retry(task.id));
    } else if (task.canResume) {
      await _manager.resume(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UDownloadTask? task = _task;
    if (task == null) return _icon(cs, Icons.download_rounded, U.s.download, cs.primary);
    return ListenableBuilder(
      listenable: task,
      builder: (BuildContext context, Widget? child) => switch (task.status) {
        UDownloadStatus.completed => _icon(cs, Icons.check_circle_rounded, U.s.open, cs.tertiary),
        UDownloadStatus.failed => _icon(cs, Icons.error_outline_rounded, uDownloadErrorLabel(task.error), cs.error),
        UDownloadStatus.canceled => _icon(cs, Icons.download_rounded, U.s.download, cs.primary),
        _ => Tooltip(
          message: uDownloadStatusLabel(task),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                UProgressCircular(value: task.total > 0 ? (task.progress * 100).round() : null, size: widget.size, strokeWidth: 3, progressColor: cs.primary),
                Icon(task.status == UDownloadStatus.paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: widget.size * 0.45, color: cs.primary),
              ],
            ),
          ).onTap(() => unawaited(_onTap())),
        ),
      },
    );
  }

  Widget _icon(ColorScheme cs, IconData icon, String tooltip, Color color) => IconButton(
    tooltip: tooltip,
    iconSize: widget.size * 0.6,
    onPressed: () => unawaited(_onTap()),
    icon: Icon(icon, color: color),
  );
}

/// Bottom sheet to paste a URL and pick where it goes — the "Add URL" box of desktop managers.
class UAddDownloadSheet extends StatefulWidget {
  const UAddDownloadSheet({super.key, this.manager, this.initialUrl});

  final UDownloadManager? manager;
  final String? initialUrl;

  static Future<UDownloadTask?> show({UDownloadManager? manager, String? initialUrl}) =>
      UNavigator.bottomSheet<UDownloadTask>(UAddDownloadSheet(manager: manager, initialUrl: initialUrl), showDragHandle: true);

  @override
  State<UAddDownloadSheet> createState() => _UAddDownloadSheetState();
}

enum _Where { downloads, saveAs, storage, vault }

class _UAddDownloadSheetState extends State<UAddDownloadSheet> {
  late final TextEditingController _url = TextEditingController(text: widget.initialUrl ?? "");
  final TextEditingController _name = TextEditingController();
  _Where _where = _Where.downloads;
  bool _wifiOnly = false;

  UDownloadManager get _manager => widget.manager ?? UDownloadManager.instance;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl == null) unawaited(_pasteFromClipboard());
  }

  Future<void> _pasteFromClipboard() async {
    final String? text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text != null && (text.startsWith("http://") || text.startsWith("https://")) && mounted) setState(() => _url.text = text);
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String url = _url.text.trim();
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return;
    final String? name = _name.text.trim().isEmpty ? null : _name.text.trim();
    final String key = name ?? url;
    final UDownloadTask task = await _manager.enqueue(
      UDownloadRequest(
        url: url,
        fileName: name,
        wifiOnly: _wifiOnly,
        destination: switch (_where) {
          _Where.downloads => const UDownloadDestination.downloads(),
          _Where.saveAs => const UDownloadDestination.saveAs(),
          _Where.storage => UDownloadDestination.storage(key),
          _Where.vault => UDownloadDestination.vault(key),
        },
      ),
    );
    if (mounted) Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UTextTitleMedium(U.s.addDownload, fontWeight: FontWeight.bold),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autofocus: widget.initialUrl == null,
          decoration: InputDecoration(labelText: U.s.url, prefixIcon: const Icon(Icons.link_rounded)),
        ).ltr(),
        TextField(controller: _name, decoration: InputDecoration(labelText: U.s.fileName)),
        UTextLabelLarge(U.s.saveTo),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final _Where where in _Where.values)
              ChoiceChip(
                label: UTextLabelMedium(switch (where) {
                  _Where.downloads => U.s.downloads,
                  _Where.saveAs => U.s.saveAs,
                  _Where.storage => U.s.appStorage,
                  _Where.vault => U.s.encryptedStorage,
                }),
                selected: _where == where,
                onSelected: (_) => setState(() => _where = where),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _wifiOnly,
          onChanged: (bool value) => setState(() => _wifiOnly = value),
          title: UTextBodyMedium(U.s.wifiOnly),
        ),
        UButton(title: U.s.download, icon: const Icon(Icons.download_rounded), fullWidth: true, onTap: () => unawaited(_submit())),
      ],
    ),
  );
}

/// Global download settings: concurrency, connections per download and a speed cap.
class UDownloadSettingsSheet extends StatefulWidget {
  const UDownloadSettingsSheet({super.key, this.manager});

  final UDownloadManager? manager;

  static Future<void> show({UDownloadManager? manager}) => UNavigator.bottomSheet<void>(UDownloadSettingsSheet(manager: manager), showDragHandle: true);

  @override
  State<UDownloadSettingsSheet> createState() => _UDownloadSettingsSheetState();
}

class _UDownloadSettingsSheetState extends State<UDownloadSettingsSheet> {
  static const List<int> _limits = <int>[0, 128 * 1024, 512 * 1024, 1024 * 1024, 5 * 1024 * 1024, 10 * 1024 * 1024];

  UDownloadManager get _manager => widget.manager ?? UDownloadManager.instance;

  @override
  Widget build(BuildContext context) {
    final UDownloadConfig config = _manager.config;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: <Widget>[
          UTextTitleMedium(U.s.settings, fontWeight: FontWeight.bold),
          UTextBodyMedium("${U.s.simultaneousDownloads}: ${config.maxConcurrent}"),
          Slider(
            value: config.maxConcurrent.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: "${config.maxConcurrent}",
            onChanged: (double v) => setState(() => _manager.maxConcurrent = v.round()),
          ),
          UTextBodyMedium("${U.s.connectionsPerDownload}: ${config.connections}"),
          Slider(
            value: config.connections.toDouble(),
            min: 1,
            max: 16,
            divisions: 15,
            label: "${config.connections}",
            onChanged: (double v) => setState(() => config.connections = v.round()),
          ),
          UTextBodyMedium(U.s.speedLimit),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final int limit in _limits)
                ChoiceChip(
                  label: UTextLabelMedium(limit == 0 ? U.s.unlimited : "${uFormatBytes(limit)}/s"),
                  selected: config.speedLimit == limit,
                  onSelected: (_) => setState(() => _manager.speedLimit = limit),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
