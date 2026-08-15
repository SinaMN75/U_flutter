import "package:u/utilities.dart";

class UAdminFileManagerPage extends StatefulWidget {
  const UAdminFileManagerPage({super.key});

  @override
  State<UAdminFileManagerPage> createState() => _UAdminFileManagerPageState();
}

enum _PreviewKind { image, video, pdf, json, text, none }

class _UAdminFileManagerPageState extends State<UAdminFileManagerPage> {
  String _path = "";
  UFileManagerListResponse? _data;
  bool _loading = true;
  bool _gridView = true;
  UFileManagerEntryResponse? _preview;

  @override
  void initState() {
    super.initState();
    _load("");
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _preview = null;
    });
    await UServices.fileManager.browse(
      p: UFileManagerBrowseParams(path: path),
      onOk: (UResponse<UFileManagerListResponse> r) => setState(() {
        _data = r.result;
        _path = r.result?.path ?? path;
        _loading = false;
      }),
      onError: (UEmptyResponse e) => setState(() {
        _loading = false;
        UToast.error(message: e.message);
      }),
      onException: (String e) => setState(() {
        _loading = false;
        UToast.error(message: e);
      }),
    );
  }

  String get _parentPath => _path.contains("/") ? _path.substring(0, _path.lastIndexOf("/")) : "";

  Future<void> _createFolder() async {
    final String? name = await UNavigator.inputDialog(title: U.s.newFolder, hint: U.s.folderName);
    if (name == null || name.trim().isEmpty) return;
    await UServices.fileManager.createFolder(
      p: UFileManagerCreateFolderParams(path: _path, name: name.trim()),
      onOk: (UEmptyResponse r) {
        UToast.snackBar(message: r.message);
        _load(_path);
      },
      onError: (UEmptyResponse e) => UToast.error(message: e.message),
      onException: (String e) => UToast.error(message: e),
    );
  }

  Future<void> _upload() async {
    await UFile.showFilePicker(
      action: (List<FileData> files) async {
        if (files.isEmpty) return;
        ULoading.show();
        for (final FileData f in files) {
          await UServices.fileManager.upload(
            p: UFileManagerUploadParams(file: f, path: _path),
            onOk: (UResponse<String> r) {},
            onError: (UEmptyResponse e) => UToast.error(message: e.message),
            onException: (String e) => UToast.error(message: e),
          );
        }
        ULoading.dismiss();
        await _load(_path);
      },
    );
  }

  Future<void> _rename(UFileManagerEntryResponse entry) async {
    final String? name = await UNavigator.inputDialog(title: U.s.rename, hint: U.s.newName, defaultValue: entry.name);
    if (name == null || name.trim().isEmpty || name.trim() == entry.name) return;
    await UServices.fileManager.rename(
      p: UFileManagerRenameParams(path: entry.path, newName: name.trim()),
      onOk: (UEmptyResponse r) {
        UToast.snackBar(message: r.message);
        _load(_path);
      },
      onError: (UEmptyResponse e) => UToast.error(message: e.message),
      onException: (String e) => UToast.error(message: e),
    );
  }

  Future<void> _move(UFileManagerEntryResponse entry) async {
    final String? destination = await UNavigator.inputDialog(title: U.s.moveTo, hint: U.s.path, defaultValue: _parentPath);
    if (destination == null) return;
    await UServices.fileManager.move(
      p: UFileManagerMoveParams(path: entry.path, destination: destination.trim()),
      onOk: (UEmptyResponse r) {
        UToast.snackBar(message: r.message);
        _load(_path);
      },
      onError: (UEmptyResponse e) => UToast.error(message: e.message),
      onException: (String e) => UToast.error(message: e),
    );
  }

  void _delete(UFileManagerEntryResponse entry) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.deleteItemConfirm,
    onConfirm: () {
      UNavigator.back();
      UServices.fileManager.delete(
        p: UFileManagerDeleteParams(path: entry.path),
        onOk: (UEmptyResponse r) {
          UToast.snackBar(message: r.message);
          if (_preview?.path == entry.path) _preview = null;
          _load(_path);
        },
        onError: (UEmptyResponse e) => UToast.error(message: e.message),
        onException: (String e) => UToast.error(message: e),
      );
    },
  );

  void _open(UFileManagerEntryResponse entry) {
    if (entry.isDirectory) {
      _load(entry.path);
    } else if (_kind(entry) != _PreviewKind.none) {
      setState(() => _preview = entry);
    } else {
      _download(entry);
    }
  }

  void _download(UFileManagerEntryResponse entry) => launchUrl(Uri.parse(UServices.fileManager.downloadUrl(entry.path)), mode: LaunchMode.externalApplication);

  void _openInBrowser(UFileManagerEntryResponse entry) => launchUrl(Uri.parse(entry.url ?? UServices.fileManager.downloadUrl(entry.path)), mode: LaunchMode.externalApplication);

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return UScaffold(
      padding: const EdgeInsets.all(20),
      body: UColumn(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(cs),
          if (_preview != null)
            _previewPane(_preview!, cs).expanded()
          else ...<Widget>[
            _toolbar(cs),
            _breadcrumb(cs),
            _body(cs).expanded(),
          ],
        ],
      ),
    );
  }

  Widget _body(ColorScheme cs) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final List<UFileManagerEntryResponse> items = _data?.all ?? <UFileManagerEntryResponse>[];
    if (items.isEmpty) return _empty(cs);
    return UContainer(
      color: cs.surface,
      radius: 16,
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      child: _gridView ? _grid(items, cs) : _list(items, cs),
    );
  }

  // ---- Header ----

  Widget _header(ColorScheme cs) {
    final int count = _data?.all.length ?? 0;
    return URow(
      spacing: 14,
      children: <Widget>[
        Icon(Icons.folder_open_rounded, size: 30, color: cs.primary).container(
          padding: const EdgeInsets.all(12),
          backgroundColor: cs.primary.withValues(alpha: 0.12),
          radius: 16,
        ),
        UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UTextHeadlineSmall(U.s.fileManager, fontWeight: FontWeight.bold),
            UTextBodySmall("wwwroot/${_path.isEmpty ? "" : _path}", color: cs.onSurface.withValues(alpha: 0.6)),
          ],
        ).expanded(),
        if (!_loading && _preview == null)
          URow(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _statChip(Icons.description_outlined, "$count", cs),
              _statChip(Icons.sd_storage_outlined, _humanSize(_data?.totalSize ?? 0), cs),
            ],
          ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, ColorScheme cs) =>
      URow(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: <Widget>[
              Icon(icon, size: 15, color: cs.onSurface.withValues(alpha: 0.6)),
              UTextLabelMedium(label, color: cs.onSurface.withValues(alpha: 0.75)),
            ],
          )
          .pSymmetric(horizontal: 12, vertical: 7)
          .container(
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            radius: 20,
          );

  // ---- Toolbar ----

  Widget _toolbar(ColorScheme cs) => URow(
    spacing: 10,
    children: <Widget>[
      _toolButton(Icons.arrow_upward_rounded, U.s.parentDirectory, _path.isEmpty ? null : () => _load(_parentPath), cs),
      _toolButton(Icons.create_new_folder_rounded, U.s.newFolder, _createFolder, cs, primary: true),
      _toolButton(Icons.upload_file_rounded, U.s.upload, _upload, cs, primary: true),
      _toolButton(Icons.refresh_rounded, U.s.refresh, () => _load(_path), cs),
      const Spacer(),
      _viewToggle(cs),
    ],
  );

  Widget _toolButton(IconData icon, String label, VoidCallback? onTap, ColorScheme cs, {bool primary = false}) {
    final bool enabled = onTap != null;
    final Color bg = primary ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final Color fg = primary ? cs.onPrimary : cs.onSurface;
    return URow(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: enabled ? fg : fg.withValues(alpha: 0.4)),
            UTextLabelLarge(label, color: enabled ? fg : fg.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
          ],
        )
        .pSymmetric(horizontal: 14, vertical: 10)
        .container(
          backgroundColor: enabled ? bg : bg.withValues(alpha: 0.4),
          radius: 10,
        )
        .onTap(enabled ? onTap : () {});
  }

  Widget _viewToggle(ColorScheme cs) =>
      URow(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _toggleSide(Icons.grid_view_rounded, _gridView, () => setState(() => _gridView = true), cs, left: true),
          _toggleSide(Icons.view_list_rounded, !_gridView, () => setState(() => _gridView = false), cs, left: false),
        ],
      ).container(
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        radius: 10,
      );

  Widget _toggleSide(IconData icon, bool active, VoidCallback onTap, ColorScheme cs, {required bool left}) =>
      Icon(
            icon,
            size: 18,
            color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
          )
          .pAll(9)
          .container(
            backgroundColor: active ? cs.primary : Colors.transparent,
            radius: 8,
          )
          .onTap(onTap);

  // ---- Breadcrumb ----

  Widget _breadcrumb(ColorScheme cs) {
    final List<String> segments = _path.isEmpty ? <String>[] : _path.split("/");
    final List<Widget> crumbs = <Widget>[
      URow(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: <Widget>[
          Icon(Icons.home_rounded, size: 16, color: segments.isEmpty ? cs.primary : cs.onSurface.withValues(alpha: 0.7)),
          UTextLabelLarge("wwwroot", color: segments.isEmpty ? cs.primary : cs.onSurface.withValues(alpha: 0.7), fontWeight: segments.isEmpty ? FontWeight.bold : FontWeight.w500),
        ],
      ).pSymmetric(horizontal: 8, vertical: 6).onTap(() => _load("")),
    ];
    String acc = "";
    for (int i = 0; i < segments.length; i++) {
      acc = acc.isEmpty ? segments[i] : "$acc/${segments[i]}";
      final String target = acc;
      final bool active = i == segments.length - 1;
      crumbs
        ..add(Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.35)))
        ..add(
          UTextLabelLarge(
            segments[i],
            color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ).pSymmetric(horizontal: 8, vertical: 6).onTap(() => _load(target)),
        );
    }
    return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: crumbs),
        )
        .pSymmetric(horizontal: 6)
        .container(
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          radius: 10,
        );
  }

  Widget _empty(ColorScheme cs) => Center(
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        Icon(Icons.folder_off_rounded, size: 56, color: cs.onSurface.withValues(alpha: 0.3)),
        UTextBodyMedium(U.s.emptyFolder, color: cs.onSurface.withValues(alpha: 0.6)),
      ],
    ),
  );

  // ---- Grid view ----

  Widget _grid(List<UFileManagerEntryResponse> items, ColorScheme cs) => SingleChildScrollView(
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double target = 190;
        final int columns = (constraints.maxWidth / target).floor().clamp(1, 8);
        final double width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((UFileManagerEntryResponse e) => SizedBox(width: width, child: _gridCard(e, cs))).toList(),
        );
      },
    ).pAll(14),
  );

  Widget _gridCard(UFileManagerEntryResponse e, ColorScheme cs) => _hoverable(
    onTap: () => _open(e),
    cs: cs,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        URow(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.6,
              child: _thumb(e, cs, radius: 10),
            ).expanded(),
          ],
        ),
        URow(
          children: <Widget>[
            Icon(_iconFor(e), size: 18, color: _accentFor(e, cs)),
            UTextBodyMedium(e.name, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis).expanded(),
            _menu(e, cs),
          ],
        ),
        UTextLabelSmall(
          e.isDirectory ? U.s.folder : _humanSize(e.size),
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ],
    ).pAll(12),
  );

  // A thumbnail: real image preview for image files, otherwise a tinted type-icon tile.
  Widget _thumb(UFileManagerEntryResponse e, ColorScheme cs, {required double radius}) {
    if (!e.isDirectory && _kind(e) == _PreviewKind.image && e.url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: UImageNetwork(e.url!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    }
    final Color accent = _accentFor(e, cs);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(_iconFor(e), size: 40, color: accent),
    );
  }

  // ---- List view ----

  Widget _list(List<UFileManagerEntryResponse> items, ColorScheme cs) => Column(
    children: <Widget>[
      _listHeader(cs),
      const Divider(height: 1),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: items.map((UFileManagerEntryResponse e) => _listRow(e, cs)).toList(),
          ),
        ),
      ),
    ],
  );

  Widget _listHeader(ColorScheme cs) => URow(
    children: <Widget>[
      UTextLabelMedium(U.s.name, color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold).expanded(flex: 5),
      UTextLabelMedium(U.s.size, color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold).expanded(flex: 2),
      UTextLabelMedium(U.s.modified, color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold).expanded(flex: 3),
      const SizedBox(width: 40),
    ],
  ).pSymmetric(horizontal: 16, vertical: 12);

  Widget _listRow(UFileManagerEntryResponse e, ColorScheme cs) => _hoverable(
    onTap: () => _open(e),
    cs: cs,
    radius: 0,
    child: URow(
      children: <Widget>[
        URow(
          spacing: 12,
          children: <Widget>[
            SizedBox(width: 34, height: 34, child: _thumb(e, cs, radius: 8)),
            UTextBodyMedium(e.name, fontWeight: FontWeight.w500, maxLines: 1, overflow: TextOverflow.ellipsis).expanded(),
          ],
        ).expanded(flex: 5),
        UTextBodySmall(e.isDirectory ? "—" : _humanSize(e.size), color: cs.onSurface.withValues(alpha: 0.7)).expanded(flex: 2),
        UTextBodySmall(_formatDate(e.modifiedAt), color: cs.onSurface.withValues(alpha: 0.7)).expanded(flex: 3),
        SizedBox(width: 40, child: _menu(e, cs)),
      ],
    ).pSymmetric(horizontal: 16, vertical: 10),
  );

  // Wraps content in a Material/InkWell so grid cards and list rows get desktop hover + splash.
  Widget _hoverable({required Widget child, required VoidCallback onTap, required ColorScheme cs, double radius = 12}) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(radius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      hoverColor: cs.primary.withValues(alpha: 0.06),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: radius > 0 ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)) : null,
        ),
        child: child,
      ),
    ),
  );

  Widget _menu(UFileManagerEntryResponse e, ColorScheme cs) => PopupMenuButton<String>(
    icon: Icon(Icons.more_vert_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
    tooltip: "",
    onSelected: (String value) {
      switch (value) {
        case "open":
          _open(e);
        case "download":
          _download(e);
        case "browser":
          _openInBrowser(e);
        case "rename":
          _rename(e);
        case "move":
          _move(e);
        case "delete":
          _delete(e);
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      if (e.isDirectory)
        PopupMenuItem<String>(value: "open", child: _menuRow(Icons.folder_open_rounded, U.s.folder))
      else ...<PopupMenuEntry<String>>[
        if (_kind(e) != _PreviewKind.none) PopupMenuItem<String>(value: "open", child: _menuRow(Icons.visibility_rounded, U.s.preview)),
        PopupMenuItem<String>(value: "download", child: _menuRow(Icons.download_rounded, U.s.download)),
        PopupMenuItem<String>(value: "browser", child: _menuRow(Icons.open_in_new_rounded, U.s.openInBrowser)),
      ],
      const PopupMenuDivider(),
      PopupMenuItem<String>(value: "rename", child: _menuRow(Icons.drive_file_rename_outline_rounded, U.s.rename)),
      PopupMenuItem<String>(value: "move", child: _menuRow(Icons.drive_file_move_rounded, U.s.move)),
      PopupMenuItem<String>(
        value: "delete",
        child: _menuRow(Icons.delete_outline_rounded, U.s.delete, color: cs.error),
      ),
    ],
  );

  Widget _menuRow(IconData icon, String label, {Color? color}) => URow(
    spacing: 10,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 18, color: color),
      UTextBodyMedium(label, color: color),
    ],
  );

  // ---- Preview pane ----

  Widget _previewPane(UFileManagerEntryResponse e, ColorScheme cs) => UContainer(
    color: cs.surface,
    radius: 16,
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    child: Column(
      children: <Widget>[
        _previewToolbar(e, cs),
        const Divider(height: 1),
        Expanded(child: _previewBody(e, cs)),
      ],
    ),
  );

  Widget _previewToolbar(UFileManagerEntryResponse e, ColorScheme cs) => URow(
    children: <Widget>[
      IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: U.s.close,
        onPressed: () => setState(() => _preview = null),
      ),
      Icon(_iconFor(e), color: _accentFor(e, cs)),
      UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextTitleSmall(e.name, fontWeight: FontWeight.bold, maxLines: 1, overflow: TextOverflow.ellipsis),
          UTextLabelSmall(_humanSize(e.size), color: cs.onSurface.withValues(alpha: 0.5)),
        ],
      ).expanded(),
      IconButton(icon: const Icon(Icons.open_in_new_rounded), tooltip: U.s.openInBrowser, onPressed: () => _openInBrowser(e)),
      IconButton(icon: const Icon(Icons.download_rounded), tooltip: U.s.download, onPressed: () => _download(e)),
    ],
  ).pSymmetric(horizontal: 8, vertical: 6);

  Widget _previewBody(UFileManagerEntryResponse e, ColorScheme cs) {
    final String url = e.url ?? UServices.fileManager.downloadUrl(e.path);
    switch (_kind(e)) {
      case _PreviewKind.image:
        return ColoredBox(
          color: Colors.black,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(child: UImageNetwork(url)),
          ),
        );
      case _PreviewKind.video:
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: UVideoPlayer(key: ValueKey<String>(e.path), url: url, autoPlay: true, borderRadius: 0),
          ),
        );
      case _PreviewKind.pdf:
        return UPdfViewer(url: url);
      case _PreviewKind.json:
        return _TextPreview(key: ValueKey<String>(e.path), url: url, asJson: true);
      case _PreviewKind.text:
        return _TextPreview(key: ValueKey<String>(e.path), url: url, asJson: false);
      case _PreviewKind.none:
        return _notPreviewable(e, cs);
    }
  }

  Widget _notPreviewable(UFileManagerEntryResponse e, ColorScheme cs) => Center(
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: <Widget>[
        Icon(_iconFor(e), size: 64, color: cs.onSurface.withValues(alpha: 0.3)),
        UTextBodyMedium(U.s.previewNotAvailable, color: cs.onSurface.withValues(alpha: 0.6)),
        UButton(
          title: U.s.download,
          icon: const Icon(Icons.download_rounded, size: 18),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          onTap: () => _download(e),
        ),
      ],
    ),
  );

  // ---- Type helpers ----

  _PreviewKind _kind(UFileManagerEntryResponse e) {
    if (e.isDirectory) return _PreviewKind.none;
    switch (e.extension) {
      case "png" || "jpg" || "jpeg" || "gif" || "webp" || "bmp" || "svg":
        return _PreviewKind.image;
      case "mp4" || "mov" || "webm" || "mkv" || "avi" || "m4v":
        return _PreviewKind.video;
      case "pdf":
        return _PreviewKind.pdf;
      case "json":
        return _PreviewKind.json;
      case "txt" || "md" || "csv" || "log" || "html" || "htm" || "xml" || "js" || "css" || "dart" || "cs" || "yaml" || "yml" || "ini" || "sh" || "sql" || "ts":
        return _PreviewKind.text;
      default:
        return _PreviewKind.none;
    }
  }

  IconData _iconFor(UFileManagerEntryResponse e) {
    if (e.isDirectory) return Icons.folder_rounded;
    switch (_kind(e)) {
      case _PreviewKind.image:
        return Icons.image_rounded;
      case _PreviewKind.video:
        return Icons.movie_rounded;
      case _PreviewKind.pdf:
        return Icons.picture_as_pdf_rounded;
      case _PreviewKind.json:
        return Icons.data_object_rounded;
      case _PreviewKind.text:
        return Icons.description_rounded;
      case _PreviewKind.none:
        break;
    }
    switch (e.extension) {
      case "mp3" || "wav" || "aac" || "ogg" || "m4a":
        return Icons.audiotrack_rounded;
      case "zip" || "rar" || "7z" || "tar" || "gz":
        return Icons.folder_zip_rounded;
      case "xls" || "xlsx":
        return Icons.table_chart_rounded;
      case "doc" || "docx":
        return Icons.article_rounded;
      case "apk":
        return Icons.android_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _accentFor(UFileManagerEntryResponse e, ColorScheme cs) {
    if (e.isDirectory) return cs.primary;
    switch (_kind(e)) {
      case _PreviewKind.image:
        return const Color(0xFF16A34A);
      case _PreviewKind.video:
        return const Color(0xFFDB2777);
      case _PreviewKind.pdf:
        return const Color(0xFFDC2626);
      case _PreviewKind.json:
        return const Color(0xFFCA8A04);
      case _PreviewKind.text:
        return const Color(0xFF2563EB);
      case _PreviewKind.none:
        return cs.onSurface.withValues(alpha: 0.55);
    }
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    const List<String> units = <String>["KB", "MB", "GB", "TB"];
    double size = bytes / 1024;
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return "${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unit]}";
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}";
  }
}

class _TextPreview extends StatefulWidget {
  const _TextPreview({required this.url, required this.asJson, super.key});

  final String url;
  final bool asJson;

  @override
  State<_TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<_TextPreview> {
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    UServices.fileManager.fetchText(
      url: widget.url,
      onOk: (String c) => setState(() => _content = c),
      onException: (String e) => setState(() => _error = e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (_error != null) return Center(child: UTextBodyMedium(_error!, color: cs.error));
    if (_content == null) return const Center(child: CircularProgressIndicator());
    if (widget.asJson) return SingleChildScrollView(child: UJsonViewer(jsonString: _content!).pAll(12));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _content!,
        style: TextStyle(fontFamily: "monospace", fontSize: 13, height: 1.5, color: cs.onSurface),
      ),
    ).ltr();
  }
}
