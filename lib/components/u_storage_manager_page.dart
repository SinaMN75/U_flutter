import "package:u/utilities.dart";

class UStorageManagerPage extends StatefulWidget {
  const UStorageManagerPage({super.key});

  @override
  State<UStorageManagerPage> createState() => _UStorageManagerPageState();
}

class _UStorageManagerPageState extends State<UStorageManagerPage> {
  List<_LocalEntry> _localEntries = <_LocalEntry>[];
  List<_FileEntry> _files = <_FileEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait<void>(<Future<void>>[_loadLocal(), _loadFiles()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLocal() async {
    final Map<String, dynamic> all = ULocalStorage.getAll();
    final List<_LocalEntry> entries = <_LocalEntry>[];
    for (final MapEntry<String, dynamic> e in all.entries) {
      if (e.key.startsWith("_expiry_")) continue;
      final dynamic rawExpiry = all["_expiry_${e.key}"];
      entries.add(
        _LocalEntry(
          key: e.key,
          value: e.value,
          expiry: rawExpiry is int ? DateTime.fromMillisecondsSinceEpoch(rawExpiry) : null,
        ),
      );
    }
    entries.sort((_LocalEntry a, _LocalEntry b) => a.key.compareTo(b.key));
    _localEntries = entries;
  }

  Future<void> _loadFiles() async {
    await UFileStorage.init();
    final List<_FileEntry> files = <_FileEntry>[];
    for (final UStorageEntry entry in UFileStorage.entries()) {
      final String mime = entry.mimeType ?? "";
      final bool isText = (mime.startsWith("text/") || mime.contains("json")) && entry.size <= 64 * 1024;
      files.add(_FileEntry(entry: entry, content: isText ? await UFileStorage.getString(entry.key, bucket: entry.bucket) : null));
    }
    files.sort((_FileEntry a, _FileEntry b) {
      final int byBucket = a.entry.bucket.index.compareTo(b.entry.bucket.index);
      return byBucket != 0 ? byBucket : a.entry.key.compareTo(b.entry.key);
    });
    _files = files;
  }

  Future<void> _deleteLocal(_LocalEntry entry) async {
    if (!await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDeleteThisEntryThisActionCannotBeUndone, destructive: true)) return;
    await ULocalStorage.remove(entry.key);
    if (entry.expiry != null) await ULocalStorage.remove("_expiry_${entry.key}");
    await _loadAll();
  }

  Future<void> _deleteFile(UStorageEntry entry) async {
    if (!await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDeleteThisEntryThisActionCannotBeUndone, destructive: true)) return;
    await UFileStorage.remove(entry.key, bucket: entry.bucket);
    await _loadAll();
  }

  Future<void> _clearLocal() async {
    if (!await UNavigator.confirmAsync(title: U.s.clearAll, message: U.s.areYouSureYouWantToDeleteAllStoredDataThisActionCannotBeUndone, destructive: true)) return;
    await ULocalStorage.clear();
    await _loadAll();
  }

  Future<void> _clearFiles() async {
    if (!await UNavigator.confirmAsync(title: U.s.clearAll, message: U.s.areYouSureYouWantToDeleteAllStoredDataThisActionCannotBeUndone, destructive: true)) return;
    await UFileStorage.clear();
    await _loadAll();
  }

  void _copy(String value) {
    UClipboard.set(value);
    UToast.snackBar(message: U.s.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: UScaffold(
        appBar: AppBar(
          title: UTextTitleLarge(U.s.storageManager, fontWeight: FontWeight.bold),
          actions: <Widget>[
            IconButton(tooltip: U.s.refresh, onPressed: _loadAll, icon: const Icon(Icons.refresh_rounded)),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: U.s.keyValue),
              Tab(text: U.s.files),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[_localTab(cs), _filesTab(cs)],
              ),
      ),
    );
  }

  Widget _localTab(ColorScheme cs) {
    if (_localEntries.isEmpty) return UEmptyState(title: U.s.noData);
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _summaryBar(cs, "${U.s.totalItems}: ${_localEntries.length}", onClear: _clearLocal),
        UListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: _localEntries.length,
          itemBuilder: (BuildContext context, int i) => _localCard(cs, _localEntries[i]),
          expanded: 1,
        ),
      ],
    );
  }

  Widget _filesTab(ColorScheme cs) {
    if (_files.isEmpty) return UEmptyState(title: U.s.noData);
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _summaryBar(cs, "${U.s.totalSize}: ${_formatBytes(UFileStorage.usage())}", onClear: _clearFiles),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: UColumn(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final UStorageBucket bucket in UStorageBucket.values)
                if (_files.any((_FileEntry f) => f.entry.bucket == bucket)) ...<Widget>[
                  _sectionLabel(cs, "${_bucketLabel(bucket)} · ${_formatBytes(UFileStorage.usage(bucket: bucket))}", _bucketIcon(bucket)),
                  ..._files.where((_FileEntry f) => f.entry.bucket == bucket).map((_FileEntry f) => _fileCard(cs, f)),
                ],
            ],
          ),
        ).expanded(),
      ],
    );
  }

  String _bucketLabel(UStorageBucket bucket) => switch (bucket) {
    UStorageBucket.support => U.s.storageSupport,
    UStorageBucket.cache => U.s.storageCache,
    UStorageBucket.vault => U.s.storageVault,
    UStorageBucket.temp => U.s.storageTemp,
  };

  IconData _bucketIcon(UStorageBucket bucket) => switch (bucket) {
    UStorageBucket.support => Icons.folder_outlined,
    UStorageBucket.cache => Icons.cached_rounded,
    UStorageBucket.vault => Icons.lock_outline_rounded,
    UStorageBucket.temp => Icons.hourglass_empty_rounded,
  };

  Widget _summaryBar(ColorScheme cs, String label, {VoidCallback? onClear}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
    child: URow(
      spacing: 8,
      children: <Widget>[
        Icon(Icons.storage_rounded, size: 16, color: cs.onSurfaceVariant),
        UTextBodySmall(label, color: cs.onSurfaceVariant, expanded: 1),
        if (onClear != null)
          TextButton.icon(
            onPressed: onClear,
            icon: Icon(Icons.delete_sweep_outlined, size: 18, color: cs.error),
            label: UTextLabelMedium(U.s.clearAll, color: cs.error),
          ),
      ],
    ),
  );

  Widget _sectionLabel(ColorScheme cs, String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 2),
    child: URow(
      spacing: 8,
      children: <Widget>[
        Icon(icon, size: 18, color: cs.primary),
        UTextTitleSmall(title, fontWeight: FontWeight.bold),
      ],
    ),
  );

  Widget _localCard(ColorScheme cs, _LocalEntry entry) => UContainer(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(14),
    radius: 16,
    color: cs.surface,
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    child: UColumn(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: UTextTitleSmall(entry.key, fontWeight: FontWeight.w700, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            _typeChip(cs, _typeLabel(entry.value)),
            _cardActions(cs, onCopy: () => _copy(_valueString(entry.value)), onDelete: () => _deleteLocal(entry)),
          ],
        ),
        _valueBlock(cs, _valueString(entry.value)),
        if (entry.expiry != null)
          URow(
            spacing: 8,
            children: <Widget>[
              Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
              UTextBodySmall("${U.s.expires}: ${entry.expiry!.formatDate("yyyy/MM/dd HH:mm")}", color: cs.onSurfaceVariant),
            ],
          ),
      ],
    ),
  );

  Widget _fileCard(ColorScheme cs, _FileEntry f) => UContainer(
    padding: const EdgeInsets.all(14),
    radius: 16,
    color: cs.surface,
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    child: UColumn(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(f.entry.isEncrypted ? Icons.lock_outline_rounded : Icons.insert_drive_file_outlined, size: 20, color: cs.primary),
            Expanded(
              child: UTextTitleSmall(f.entry.key, fontWeight: FontWeight.w700, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            _typeChip(cs, _formatBytes(f.entry.size)),
            _cardActions(cs, onCopy: f.content == null ? null : () => _copy(f.content!), onDelete: () => _deleteFile(f.entry)),
          ],
        ),
        if (f.content != null) _valueBlock(cs, f.content!),
        if (f.entry.mimeType != null || f.entry.expires != null)
          URow(
            spacing: 8,
            children: <Widget>[
              if (f.entry.mimeType != null) UTextBodySmall(f.entry.mimeType!, color: cs.onSurfaceVariant),
              if (f.entry.expires != null) ...<Widget>[
                Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
                UTextBodySmall("${U.s.expires}: ${f.entry.expires!.formatDate("yyyy/MM/dd HH:mm")}", color: cs.onSurfaceVariant),
              ],
            ],
          ),
      ],
    ),
  );

  Widget _cardActions(ColorScheme cs, {required VoidCallback onDelete, VoidCallback? onCopy}) => URow(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (onCopy != null)
        IconButton(
          tooltip: U.s.copyToClipboard,
          visualDensity: VisualDensity.compact,
          onPressed: onCopy,
          icon: Icon(Icons.copy_rounded, size: 18, color: cs.primary),
        ),
      IconButton(
        tooltip: U.s.delete,
        visualDensity: VisualDensity.compact,
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
      ),
    ],
  );

  Widget _typeChip(ColorScheme cs, String label) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    radius: 20,
    color: cs.primary.withValues(alpha: 0.14),
    child: UTextBodySmall(label, color: cs.primary, fontWeight: FontWeight.w600),
  );

  Widget _valueBlock(ColorScheme cs, String value) => UContainer(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    radius: 8,
    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
    child: SelectableText(
      value.isEmpty ? "—" : value,
      maxLines: 8,
      style: TextStyle(fontFamily: "monospace", fontSize: 13, height: 1.5, color: cs.onSurface),
    ).ltr(),
  );

  String _typeLabel(dynamic value) => switch (value) {
    String() => "String",
    bool() => "bool",
    int() => "int",
    double() => "double",
    List<String>() => "List",
    _ => value.runtimeType.toString(),
  };

  String _valueString(dynamic value) => value is List<String> ? value.join(", ") : value.toString();

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
}

class _LocalEntry {
  const _LocalEntry({required this.key, required this.value, this.expiry});

  final String key;
  final dynamic value;
  final DateTime? expiry;
}

class _FileEntry {
  const _FileEntry({required this.entry, this.content});

  final UStorageEntry entry;
  final String? content;
}
