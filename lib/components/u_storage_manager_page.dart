import "package:u/utilities.dart";

class UStorageManagerPage extends StatefulWidget {
  const UStorageManagerPage({super.key});

  @override
  State<UStorageManagerPage> createState() => _UStorageManagerPageState();
}

class _UStorageManagerPageState extends State<UStorageManagerPage> {
  List<_LocalEntry> _localEntries = <_LocalEntry>[];
  List<_TextFile> _textFiles = <_TextFile>[];
  Map<String, int> _binaryFiles = <String, int>{};
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
    if (kIsWeb) {
      _textFiles = <_TextFile>[];
      _binaryFiles = <String, int>{};
      return;
    }
    final List<String> keys = await UFileStorage.getKeys();
    final List<_TextFile> texts = <_TextFile>[];
    for (final String key in keys) {
      texts.add(_TextFile(key: key, content: await UFileStorage.getString(key)));
    }
    texts.sort((_TextFile a, _TextFile b) => a.key.compareTo(b.key));
    _textFiles = texts;
    _binaryFiles = UFileStorage.allFilesStorageInfo();
  }

  Future<void> _deleteLocal(_LocalEntry entry) async {
    if (!await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDeleteThisEntryThisActionCannotBeUndone, destructive: true)) return;
    await ULocalStorage.remove(entry.key);
    if (entry.expiry != null) await ULocalStorage.remove("_expiry_${entry.key}");
    await _loadAll();
  }

  Future<void> _deleteFile(String key) async {
    if (!await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDeleteThisEntryThisActionCannotBeUndone, destructive: true)) return;
    await UFileStorage.remove(key);
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
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _summaryBar(cs, "${U.s.totalItems}: ${_localEntries.length}", onClear: _clearLocal),
        UListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: _localEntries.length,
          itemBuilder: (BuildContext context, int i) => _localCard(cs, _localEntries[i]),
        ).expanded(),
      ],
    );
  }

  Widget _filesTab(ColorScheme cs) {
    if (kIsWeb) return UEmptyState(title: U.s.noData);
    if (_textFiles.isEmpty && _binaryFiles.isEmpty) return UEmptyState(title: U.s.noData);
    final List<MapEntry<String, int>> binaries = _binaryFiles.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => a.key.compareTo(b.key));
    final int totalBytes = _binaryFiles.values.fold(0, (int sum, int s) => sum + s);
    return UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _summaryBar(cs, "${U.s.totalSize}: ${_formatBytes(totalBytes)}", onClear: _textFiles.isEmpty && binaries.isEmpty ? null : _clearFiles),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: UColumn(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_textFiles.isNotEmpty) ...<Widget>[
                _sectionLabel(cs, U.s.textFiles, Icons.description_outlined),
                ..._textFiles.map((_TextFile f) => _textFileCard(cs, f)),
              ],
              if (binaries.isNotEmpty) ...<Widget>[
                _sectionLabel(cs, U.s.binaryFiles, Icons.data_object_rounded),
                ...binaries.map((MapEntry<String, int> e) => _binaryFileCard(cs, e.key, e.value)),
              ],
            ],
          ),
        ).expanded(),
      ],
    );
  }

  Widget _summaryBar(ColorScheme cs, String label, {VoidCallback? onClear}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
    child: URow(
      children: <Widget>[
        Icon(Icons.storage_rounded, size: 16, color: cs.onSurfaceVariant),
        UTextBodySmall(label, color: cs.onSurfaceVariant).expanded(),
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
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
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
            spacing: 6,
            children: <Widget>[
              Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
              UTextBodySmall("${U.s.expires}: ${entry.expiry!.formatDate("yyyy/MM/dd HH:mm")}", color: cs.onSurfaceVariant),
            ],
          ),
      ],
    ),
  );

  Widget _textFileCard(ColorScheme cs, _TextFile f) => UContainer(
    padding: const EdgeInsets.all(14),
    radius: 16,
    color: cs.surface,
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    child: UColumn(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: UTextTitleSmall("${f.key}.txt", fontWeight: FontWeight.w700, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            _typeChip(cs, _formatBytes(f.content?.length ?? 0)),
            _cardActions(cs, onCopy: f.content == null ? null : () => _copy(f.content!), onDelete: () => _deleteFile(f.key)),
          ],
        ),
        _valueBlock(cs, f.content ?? ""),
      ],
    ),
  );

  Widget _binaryFileCard(ColorScheme cs, String key, int size) => UContainer(
    padding: const EdgeInsets.all(14),
    radius: 16,
    color: cs.surface,
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    child: URow(
      spacing: 12,
      children: <Widget>[
        UContainer(
          width: 44,
          height: 44,
          radius: 12,
          color: cs.primary.withValues(alpha: 0.12),
          alignment: Alignment.center,
          child: Icon(Icons.insert_drive_file_outlined, color: cs.primary, size: 22),
        ),
        UColumn(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UTextTitleSmall("$key.dat", fontWeight: FontWeight.w700, maxLines: 1, overflow: TextOverflow.ellipsis),
            UTextBodySmall("${U.s.size}: ${_formatBytes(size)}", color: cs.onSurfaceVariant),
          ],
        ).expanded(),
        IconButton(
          tooltip: U.s.delete,
          onPressed: () => _deleteFile(key),
          icon: Icon(Icons.delete_outline_rounded, color: cs.error),
        ),
      ],
    ),
  );

  Widget _cardActions(ColorScheme cs, {required VoidCallback onDelete, VoidCallback? onCopy}) => URow(
    spacing: 0,
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

class _TextFile {
  const _TextFile({required this.key, this.content});

  final String key;
  final String? content;
}
