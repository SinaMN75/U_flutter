import "package:u/utilities.dart";

class UPdfAnnotationsPanel extends StatefulWidget {
  const UPdfAnnotationsPanel({required this.editor, required this.onJump, super.key});

  final UPdfEditController editor;
  final void Function(int pageIndex) onJump;

  @override
  State<UPdfAnnotationsPanel> createState() => _UPdfAnnotationsPanelState();
}

class _UPdfAnnotationsPanelState extends State<UPdfAnnotationsPanel> {
  List<UPdfAnnotationInfo> _items = <UPdfAnnotationInfo>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final List<UPdfAnnotationInfo> items = await widget.editor.allAnnotations();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _editNote(UPdfAnnotationInfo info) async {
    final TextEditingController field = TextEditingController(text: info.contents);
    final String? value = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(U.s.note),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.save)),
        ],
      ),
    );
    field.dispose();
    if (value == null) return;
    await widget.editor.updateAnnotation(info.pageIndex, info.objectNumber, contents: value);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(child: UTextTitleMedium(U.s.annotations)),
            UTextBodySmall("${_items.length}"),
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(child: UTextBodyMedium(U.s.noResults))
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (BuildContext context, int index) {
                  final UPdfAnnotationInfo info = _items[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: info.color ?? const Color(0xFF9E9E9E), shape: BoxShape.circle),
                    ),
                    title: UTextBodyMedium(info.contents.isEmpty ? info.subtype : info.contents, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: UTextBodySmall("${U.s.page} ${info.pageIndex + 1}${info.author.isEmpty ? "" : " · ${info.author}"}"),
                    onTap: () {
                      UNavigator.back<void>();
                      widget.onJump(info.pageIndex);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(icon: const Icon(Icons.edit_note_rounded, size: 18), onPressed: () => unawaited(_editNote(info))),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          onPressed: () async {
                            await widget.editor.deleteAnnotation(info.pageIndex, info.objectNumber);
                            await _load();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

class UPdfPageManagerPanel extends StatefulWidget {
  const UPdfPageManagerPanel({required this.viewer, required this.editor, this.onJump, super.key});

  final UPdfController viewer;
  final UPdfEditController editor;
  final void Function(int pageIndex)? onJump;

  @override
  State<UPdfPageManagerPanel> createState() => _UPdfPageManagerPanelState();
}

class _UPdfPageManagerPanelState extends State<UPdfPageManagerPanel> {
  final Set<int> _selected = <int>{};
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  List<int> get _targets => _selected.isEmpty ? <int>[] : (_selected.toList()..sort());

  Future<void> _saveCopy(Uint8List? bytes, String suggested) async {
    if (bytes == null) {
      UToast.errorToast(message: U.s.couldNotOpenTheDocument);
      return;
    }
    await UShare.bytes(bytes: bytes, fileName: suggested, mimeType: "application/pdf");
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: UTextTitleMedium(U.s.pages)),
            if (_selected.isNotEmpty) UTextBodySmall("${_selected.length}"),
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              tooltip: U.s.selectAll,
              onPressed: () => setState(() => _selected.addAll(List<int>.generate(widget.viewer.pageCount, (int i) => i))),
            ),
            IconButton(icon: const Icon(Icons.deselect_rounded), tooltip: U.s.clear, onPressed: () => setState(_selected.clear)),
          ],
        ),
      ),
      SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: _busy ? null : () => unawaited(_run(() => widget.editor.insertBlankPage(widget.viewer.pageCount))),
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: UTextBodySmall(U.s.add),
              ),
              TextButton.icon(
                onPressed: _busy || _selected.isEmpty
                    ? null
                    : () => unawaited(
                        _run(() async {
                          for (final int index in _targets.reversed) {
                            await widget.editor.rotatePage(index, 90);
                          }
                        }),
                      ),
                icon: const Icon(Icons.rotate_right_rounded, size: 18),
                label: UTextBodySmall(U.s.rotate),
              ),
              TextButton.icon(
                onPressed: _busy || _selected.isEmpty
                    ? null
                    : () => unawaited(
                        _run(() async {
                          final List<int> doomed = _targets;
                          final UPdfEdit? edit = widget.editor.edit;
                          if (edit != null) await edit.deletePages(doomed);
                          widget.viewer.invalidateAll();
                          _selected.clear();
                        }),
                      ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: UTextBodySmall(U.s.delete),
              ),
              TextButton.icon(
                onPressed: _busy || _selected.isEmpty ? null : () => unawaited(_run(() async => _saveCopy(await widget.editor.exportPages(_targets), "extract.pdf"))),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: UTextBodySmall(U.s.extract),
              ),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => unawaited(
                        _run(() async {
                          final FileData? picked = await UFile.pickFile(fileType: FileType.custom, allowedExtensions: <String>["pdf"]);
                          final String? path = picked?.path;
                          if (path == null) return;
                          final bool merged = await widget.editor.mergeFile(path);
                          if (!merged) UToast.errorToast(message: U.s.couldNotOpenTheDocument);
                        }),
                      ),
                icon: const Icon(Icons.merge_rounded, size: 18),
                label: UTextBodySmall(U.s.merge),
              ),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => unawaited(
                        _run(() async {
                          final UPdfDocument? document = widget.viewer.document;
                          if (document == null) return;
                          final List<Uint8List> parts = await UPdfOps.split(document);
                          if (parts.isEmpty) return;
                          await _saveCopy(parts.first, "split_1.pdf");
                        }),
                      ),
                icon: const Icon(Icons.call_split_rounded, size: 18),
                label: UTextBodySmall(U.s.split),
              ),
            ],
          ),
        ),
      ),
      if (_busy) const LinearProgressIndicator(),
      Expanded(
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          itemCount: widget.viewer.pageCount,
          onReorder: (int oldIndex, int newIndex) => unawaited(
            _run(() async {
              final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
              await widget.editor.movePage(oldIndex, target);
              _selected.clear();
            }),
          ),
          itemBuilder: (BuildContext context, int index) {
            final bool selected = _selected.contains(index);
            return Padding(
              key: ValueKey<int>(index),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => setState(() => selected ? _selected.remove(index) : _selected.add(index)),
                onDoubleTap: () {
                  UNavigator.back<void>();
                  widget.onJump?.call(index);
                },
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor, width: selected ? 3 : 1),
                            color: const Color(0xFFFFFFFF),
                          ),
                          child: UPdfThumbnail(controller: widget.viewer, pageIndex: index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    UTextBodySmall("${index + 1}"),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class UPdfDocumentToolsPanel extends StatefulWidget {
  const UPdfDocumentToolsPanel({required this.viewer, required this.editor, super.key});

  final UPdfController viewer;
  final UPdfEditController editor;

  @override
  State<UPdfDocumentToolsPanel> createState() => _UPdfDocumentToolsPanelState();
}

class _UPdfDocumentToolsPanelState extends State<UPdfDocumentToolsPanel> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<String?> _ask(String title, {String initial = ""}) async {
    final TextEditingController field = TextEditingController(text: initial);
    final String? value = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(title),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.save)),
        ],
      ),
    );
    field.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: UTextTitleMedium(U.s.tools)),
        if (_busy) const LinearProgressIndicator(),
        ListTile(
          leading: const Icon(Icons.branding_watermark_outlined),
          title: UTextBodyMedium(U.s.watermark),
          onTap: () => unawaited(
            _run(() async {
              final String? text = await _ask(U.s.watermark);
              if (text == null || text.trim().isEmpty) return;
              await widget.editor.addWatermark(text);
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.numbers_rounded),
          title: UTextBodyMedium(U.s.pageNumbers),
          onTap: () => unawaited(_run(() => widget.editor.addPageNumbers())),
        ),
        ListTile(
          leading: const Icon(Icons.hide_source_rounded),
          title: UTextBodyMedium(U.s.applyRedactions),
          subtitle: UTextBodySmall(U.s.removesTheHiddenTextPermanently),
          onTap: () => unawaited(
            _run(() async {
              final int removed = await widget.editor.applyPendingRedactions();
              UToast.toast(message: "${U.s.applyRedactions} · $removed");
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.layers_clear_rounded),
          title: UTextBodyMedium(U.s.flatten),
          onTap: () => unawaited(_run(() => widget.editor.flatten())),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: UTextBodyMedium(U.s.documentInfo),
          onTap: () => unawaited(
            _run(() async {
              final String? title = await _ask(U.s.title, initial: widget.viewer.value.metadata.displayTitle);
              if (title == null) return;
              await widget.editor.setMetadata(widget.viewer.value.metadata.copyWith(title: title));
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.print_rounded),
          title: UTextBodyMedium(U.s.print),
          onTap: () => unawaited(_run(() => UPdfExport.sharePrintable(widget.viewer).then((bool _) {}))),
        ),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: UTextBodyMedium(U.s.exportImages),
          onTap: () => unawaited(_run(() => UPdfExport.shareImages(widget.viewer, pages: <int>[widget.viewer.value.pageIndex]).then((bool _) {}))),
        ),
        ListTile(
          leading: const Icon(Icons.compress_rounded),
          title: UTextBodyMedium(U.s.optimize),
          onTap: () => unawaited(
            _run(() async {
              final UPdfEdit? edit = widget.editor.edit;
              if (edit == null) return;
              final Uint8List? bytes = await edit.composeCurrent();
              if (bytes == null) return;
              await UShare.bytes(bytes: bytes, fileName: "optimized.pdf", mimeType: "application/pdf");
            }),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.grid_view_rounded),
          title: UTextBodyMedium(U.s.nUp),
          onTap: () => unawaited(
            _run(() async {
              final UPdfDocument? document = widget.viewer.document;
              if (document == null) return;
              final Uint8List? bytes = await UPdfOps.nUp(document);
              if (bytes == null) return;
              await UShare.bytes(bytes: bytes, fileName: "nup.pdf", mimeType: "application/pdf");
            }),
          ),
        ),
      ],
    ),
  );
}
