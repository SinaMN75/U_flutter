import "dart:ui" as ui;

import "package:u/utilities.dart";

/// A tag/category (e.g. TagMedia) users can assign to picked files.
class UFilePickerCategory {
  const UFilePickerCategory({required this.value, required this.title});

  /// Current value.
  final int value;

  /// Title text.
  final String title;
}

/// State of a [UFilePicker]: already-uploaded files, newly picked files, removals and the cover.
class UFilePickerController extends ChangeNotifier {
  UFilePickerController({List<UFileData> existingFiles = const <UFileData>[], List<UFileData> files = const <UFileData>[], this._cover})
    : _existing = List<UFileData>.from(existingFiles),
      _files = List<UFileData>.from(files);

  /// Starts from already-uploaded media; the one tagged [TagMedia.cover] is the cover.
  factory UFilePickerController.fromMedia(List<UMediaResponse> media) {
    final List<UFileData> existing = media.map((UMediaResponse m) => UFileData(id: m.id, url: m.url, tags: m.tags, name: m.path.fileName)).toList();
    return UFilePickerController(existingFiles: existing, cover: existing.where((UFileData f) => f.tags?.contains(TagMedia.cover.number) ?? false).firstOrNull);
  }

  final List<UFileData> _existing;
  final List<UFileData> _files;
  final List<UFileData> _removed = <UFileData>[];
  UFileData? _cover;
  bool _coverChanged = false;

  /// Already-uploaded files that are still kept.
  List<UFileData> get existingFiles => List<UFileData>.unmodifiable(_existing);

  /// Newly picked files; a picked file's category is its first tag.
  List<UFileData> get files => List<UFileData>.unmodifiable(_files);

  /// Already-uploaded files the user removed.
  List<UFileData> get removedFiles => List<UFileData>.unmodifiable(_removed);

  /// Every file (existing + new).
  List<UFileData> get all => <UFileData>[..._existing, ..._files];

  /// File marked as cover.
  UFileData? get cover => _cover;

  /// True when the cover changed.
  bool get coverChanged => _coverChanged;

  /// True when files were added/removed/changed.
  bool get hasChanges => _files.isNotEmpty || _removed.isNotEmpty || _coverChanged;

  /// True for a file picked in this session (not uploaded yet).
  bool isNew(UFileData file) => _files.contains(file);

  /// True when [file] is the cover.
  bool isCover(UFileData file) => identical(file, _cover);

  /// Adds files.
  void add(Iterable<UFileData> files) {
    _files.addAll(files);
    notifyListeners();
  }

  /// Replaces all files.
  void replace(Iterable<UFileData> files) {
    if (_files.contains(_cover)) _setCover(null);
    _files
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  /// Removes a file.
  void remove(UFileData file) {
    if (identical(file, _cover)) _setCover(null);
    if (_existing.remove(file)) {
      _removed.add(file);
    } else {
      _files.remove(file);
    }
    notifyListeners();
  }

  /// Marks the cover file.
  void setCover(UFileData? file) {
    _setCover(file);
    notifyListeners();
  }

  void _setCover(UFileData? file) {
    if (identical(file, _cover)) return;
    _cover = file;
    _coverChanged = true;
  }
}

/// The one widget for selecting multiple files: new picks, already-uploaded files, categories and a cover.
class UFilePicker extends StatefulWidget {
  const UFilePicker({
    super.key,
    this.controller,
    this.onFilesChanged,
    this.initialFiles = const <UFileData>[],
    this.allowMultipleSelection = true,
    this.selectFileTitle,
    this.subtitle,
    this.imageTypes = const <String>["jpg", "jpeg", "png", "gif", "bmp", "webp"],
    this.videoTypes = const <String>["mp4", "mov", "avi", "mkv", "webm"],
    this.documentTypes = const <String>["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt"],
    this.allowedExtensions,
    this.fileType = FileType.custom,
    this.categories = const <UFilePickerCategory>[],
    this.categoryTitle,
    this.selectCover = false,
    this.enabled = true,
    this.tileExtent = 140,
    this.icon = Icons.cloud_upload_outlined,
  });

  /// Holds existing files, removals and the cover; created internally when omitted.
  final UFilePickerController? controller;

  /// Called with the newly picked files whenever they change.
  final ValueChanged<List<UFileData>>? onFilesChanged;

  /// New files to start with when no [controller] is given.
  final List<UFileData> initialFiles;

  /// Lets the user pick several files.
  final bool allowMultipleSelection;

  /// Title of the add button.
  final String? selectFileTitle;

  /// Second line of text.
  final String? subtitle;

  /// Extensions treated as images.
  final List<String> imageTypes;

  /// Extensions treated as videos.
  final List<String> videoTypes;

  /// Extensions treated as documents.
  final List<String> documentTypes;

  /// Overrides [imageTypes] + [videoTypes] + [documentTypes] as the accepted extensions.
  final List<String>? allowedExtensions;

  /// Which files the picker offers.
  final FileType fileType;

  /// Categories users can assign.
  final List<UFilePickerCategory> categories;

  /// Title of the category chooser.
  final String? categoryTitle;

  /// Lets the user mark a cover image.
  final bool selectCover;

  /// False disables interaction and greys it out.
  final bool enabled;

  /// Preferred tile width; the grid fits as many columns as the width allows.
  final double tileExtent;

  /// Icon shown with it.
  final IconData icon;

  /// Photos of a place (hotel, room, dorm, bed): images only, a category per photo and a cover. Save with [UMediaService.syncGallery].
  static Widget gallery(UFilePickerController controller) => UFilePicker(
    controller: controller,
    selectFileTitle: U.s.addPhotos,
    allowedExtensions: const <String>["jpg", "jpeg", "png", "webp"],
    categoryTitle: U.s.photoCategory,
    categories: TagMedia.values.group(300).map((TagMedia c) => UFilePickerCategory(value: c.number, title: c.localizedTitle)).toList(),
    selectCover: true,
  );

  @override
  State<UFilePicker> createState() => _UFilePickerState();
}

class _UFilePickerState extends State<UFilePicker> {
  static const double _spacing = 10;

  UFilePickerController? _own;
  int? _category;
  bool _picking = false;

  UFilePickerController get _c => widget.controller ?? (_own ??= UFilePickerController(files: widget.initialFiles));

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(UFilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    (oldWidget.controller ?? _own)?.removeListener(_onChanged);
    _c.addListener(_onChanged);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _own?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<String>? get _extensions {
    if (widget.allowedExtensions != null) return widget.allowedExtensions;
    if (widget.fileType != FileType.custom) return null;
    return <String>[...widget.imageTypes, ...widget.videoTypes, ...widget.documentTypes];
  }

  bool _isImage(UFileData file) {
    final String? ext = file.extension?.toLowerCase();
    if (ext == null) return !file.hasBytes && file.url != null;
    return widget.imageTypes.contains(ext) || UFile.isImageExtension(ext);
  }

  Future<void> _pick() async {
    if (_picking || !widget.enabled) return;
    setState(() => _picking = true);
    final List<String>? extensions = _extensions;
    final List<UFileData> picked = await UFile.pickFiles(
      allowMultiple: widget.allowMultipleSelection,
      fileType: extensions == null ? widget.fileType : FileType.custom,
      allowedExtensions: extensions,
    );
    if (!mounted) return;
    setState(() => _picking = false);
    if (picked.isEmpty) return;
    final List<UFileData> tagged = _category == null ? picked : picked.map((UFileData f) => UFileData(bytes: f.bytes, extension: f.extension, name: f.name, tags: <int>[_category!])).toList();
    if (widget.allowMultipleSelection) {
      _c.add(tagged);
    } else {
      _c.replace(tagged.take(1));
    }
    widget.onFilesChanged?.call(_c.files);
  }

  void _remove(UFileData file) {
    final bool isNew = _c.isNew(file);
    _c.remove(file);
    if (isNew) widget.onFilesChanged?.call(_c.files);
  }

  void _open(UFileData file) {
    if (_isImage(file) && file.extension != "svg") UNavigator.push(UImageViewer(fileData: file));
  }

  String _categoryTitle(UFileData file) {
    for (final UFilePickerCategory c in widget.categories) {
      if (file.tags?.contains(c.value) ?? false) return c.title;
    }
    return "";
  }

  String? _formatsHint() {
    final List<String>? extensions = _extensions;
    if (extensions == null || extensions.isEmpty) return null;
    final List<String> shown = extensions.take(6).map((String e) => e.toUpperCase()).toList();
    final int more = extensions.length - shown.length;
    return "${shown.join(" · ")}${more > 0 ? "  +$more" : ""}";
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<UFileData> all = _c.all;
    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : widget.tileExtent * 3 + _spacing * 2;
          final int columns = max(2, ((width + _spacing) / (widget.tileExtent + _spacing)).floor());
          final double tile = (width - _spacing * (columns - 1)) / columns;
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: AlignmentDirectional.topStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.categories.isNotEmpty) _categoryBar(scheme),
                if (all.isEmpty)
                  _DropZone(
                    icon: widget.icon,
                    title: widget.selectFileTitle ?? U.s.selectFiles,
                    subtitle: widget.subtitle ?? U.s.tapToBrowseYourFiles,
                    formats: _formatsHint(),
                    busy: _picking,
                    enabled: widget.enabled,
                    onTap: _pick,
                  )
                else ...<Widget>[
                  _header(scheme, all),
                  Wrap(
                    spacing: _spacing,
                    runSpacing: _spacing,
                    children: <Widget>[
                      ...all.map(
                        (UFileData f) => _isImage(f)
                            ? _ImageTile(
                                file: f,
                                size: tile,
                                caption: _categoryTitle(f),
                                isCover: _c.isCover(f),
                                isNew: _c.isNew(f) && _c.existingFiles.isNotEmpty,
                                selectCover: widget.selectCover,
                                enabled: widget.enabled,
                                onTap: () => _open(f),
                                onCover: () => _c.setCover(f),
                                onRemove: () => _remove(f),
                              )
                            : _FileTile(file: f, size: tile, caption: _categoryTitle(f), isNew: _c.isNew(f) && _c.existingFiles.isNotEmpty, enabled: widget.enabled, onRemove: () => _remove(f)),
                      ),
                      if (widget.enabled)
                        _AddTile(
                          size: tile,
                          icon: widget.allowMultipleSelection ? Icons.add_rounded : Icons.swap_horiz_rounded,
                          label: widget.allowMultipleSelection ? U.s.add : U.s.change,
                          busy: _picking,
                          onTap: _pick,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryBar(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (widget.categoryTitle != null) UTextLabelLarge(widget.categoryTitle!, color: scheme.onSurfaceVariant).pOnly(bottom: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.categories
              .map(
                (UFilePickerCategory c) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    label: Text(c.title),
                    selected: _category == c.value,
                    showCheckmark: false,
                    onSelected: widget.enabled ? (bool on) => setState(() => _category = on ? c.value : null) : null,
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _header(ColorScheme scheme, List<UFileData> all) {
    final int bytes = all.fold(0, (int sum, UFileData f) => sum + (f.sizeInBytes ?? 0));
    return Row(
      children: <Widget>[
        Icon(Icons.perm_media_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: UTextLabelLarge(widget.selectFileTitle ?? U.s.files, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        _Pill(text: "${all.length}", background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
        if (bytes > 0) ...<Widget>[
          const SizedBox(width: 8),
          UTextLabelMedium(_formatSize(bytes), color: scheme.onSurfaceVariant).ltr(),
        ],
      ],
    ).pOnly(bottom: 12);
  }
}

String _formatSize(int bytes) {
  if (bytes <= 0) return "0 B";
  const List<String> units = <String>["B", "KB", "MB", "GB", "TB"];
  final int i = min((log(bytes) / log(1024)).floor(), units.length - 1);
  final double value = bytes / pow(1024, i);
  return "${i == 0 || value >= 100 || value == value.roundToDouble() ? value.round() : value.toStringAsFixed(1)} ${units[i]}";
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background, required this.foreground, this.icon});

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[Icon(icon, size: 13, color: foreground), const SizedBox(width: 4)],
        Flexible(
          child: UTextLabelSmall(text, color: foreground, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.tooltip, required this.onTap, this.color});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 16, color: color ?? scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.file,
    required this.size,
    required this.caption,
    required this.isCover,
    required this.isNew,
    required this.selectCover,
    required this.enabled,
    required this.onTap,
    required this.onCover,
    required this.onRemove,
  });

  final UFileData file;
  final double size;
  final String caption;
  final bool isCover;
  final bool isNew;
  final bool selectCover;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int? bytes = file.sizeInBytes;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCover ? scheme.tertiary : scheme.outlineVariant, width: isCover ? 2.5 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCover ? 13.5 : 15),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Material(
              color: scheme.surfaceContainerHighest,
              child: InkWell(onTap: onTap, child: _preview(scheme)),
            ),
            PositionedDirectional(
              top: 6,
              start: 6,
              end: 60,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: isCover
                    ? _Pill(text: U.s.cover, icon: Icons.star_rounded, background: scheme.tertiary, foreground: scheme.onTertiary)
                    : isNew
                    ? _Pill(text: U.s.newFile, background: scheme.primary, foreground: scheme.onPrimary)
                    : const SizedBox.shrink(),
              ),
            ),
            if (enabled)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: Row(
                  children: <Widget>[
                    if (selectCover && !isCover) ...<Widget>[_CircleAction(icon: Icons.star_border_rounded, tooltip: U.s.setAsCover, color: scheme.tertiary, onTap: onCover), const SizedBox(width: 4)],
                    _CircleAction(icon: Icons.close_rounded, tooltip: U.s.remove, onTap: onRemove),
                  ],
                ),
              ),
            if (caption.isNotEmpty || (bytes != null && bytes > 0))
              PositionedDirectional(
                start: 6,
                end: 6,
                bottom: 6,
                child: Row(
                  children: <Widget>[
                    if (caption.isNotEmpty)
                      Flexible(
                        child: _Pill(text: caption, background: scheme.inverseSurface.withValues(alpha: 0.78), foreground: scheme.onInverseSurface),
                      ),
                    const Spacer(),
                    if (bytes != null && bytes > 0) _Pill(text: _formatSize(bytes), background: scheme.inverseSurface.withValues(alpha: 0.78), foreground: scheme.onInverseSurface).ltr(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _preview(ColorScheme scheme) {
    final Widget fallback = Center(child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant));
    if (file.hasBytes && file.extension == "svg") return SvgPicture.memory(file.bytes!, fit: BoxFit.cover);
    if (file.hasBytes) return Image.memory(file.bytes!, fit: BoxFit.cover, cacheWidth: (size * 3).round(), gaplessPlayback: true, errorBuilder: (_, _, _) => fallback);
    if (file.url == null) return fallback;
    return UImage(file.url!, fit: BoxFit.cover, width: size, height: size);
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.size, required this.caption, required this.isNew, required this.enabled, required this.onRemove});

  final UFileData file;
  final double size;
  final String caption;
  final bool isNew;
  final bool enabled;
  final VoidCallback onRemove;

  static (IconData, Color) _style(String ext, ColorScheme scheme) => switch (ext) {
    "pdf" => (Icons.picture_as_pdf_outlined, scheme.error),
    "doc" || "docx" || "txt" || "rtf" => (Icons.description_outlined, scheme.primary),
    "xls" || "xlsx" || "csv" => (Icons.table_chart_outlined, scheme.primary),
    "ppt" || "pptx" => (Icons.slideshow_outlined, scheme.tertiary),
    "mp4" || "mov" || "avi" || "mkv" || "webm" => (Icons.movie_outlined, scheme.secondary),
    "mp3" || "wav" || "aac" || "m4a" || "ogg" => (Icons.audiotrack_outlined, scheme.secondary),
    "zip" || "rar" || "7z" => (Icons.folder_zip_outlined, scheme.onSurfaceVariant),
    _ => (Icons.insert_drive_file_outlined, scheme.onSurfaceVariant),
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String ext = (file.extension ?? "").toLowerCase();
    final (IconData icon, Color color) = _style(ext, scheme);
    final int? bytes = file.sizeInBytes;
    final String details = <String>[if (ext.isNotEmpty) ext.toUpperCase(), if (bytes != null && bytes > 0) _formatSize(bytes)].join(" · ");
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: size * 0.18),
                ),
                const SizedBox(height: 8),
                UTextLabelMedium(file.name ?? file.url?.fileName ?? "", fontWeight: FontWeight.w600, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                if (details.isNotEmpty) UTextLabelSmall(details, color: scheme.onSurfaceVariant, maxLines: 1).ltr(),
                if (caption.isNotEmpty) UTextLabelSmall(caption, color: scheme.primary, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isNew)
            PositionedDirectional(
              top: 6,
              start: 6,
              child: _Pill(text: U.s.newFile, background: scheme.primary, foreground: scheme.onPrimary),
            ),
          if (enabled)
            PositionedDirectional(
              top: 6,
              end: 6,
              child: _CircleAction(icon: Icons.close_rounded, tooltip: U.s.remove, onTap: onRemove),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.icon, required this.label, required this.busy, required this.onTap});

  final double size;
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: scheme.primary.withValues(alpha: 0.5), radius: 16),
        child: Material(
          color: scheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: busy ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (busy) SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.primary)) else Icon(icon, size: 30, color: scheme.primary),
                const SizedBox(height: 6),
                UTextLabelLarge(label, color: scheme.primary, fontWeight: FontWeight.w600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropZone extends StatefulWidget {
  const _DropZone({required this.icon, required this.title, required this.subtitle, required this.busy, required this.enabled, required this.onTap, this.formats});

  final IconData icon;
  final String title;
  final String subtitle;
  final String? formats;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool active = _hover && widget.enabled;
    return CustomPaint(
      painter: _DashedBorderPainter(color: active ? scheme.primary : scheme.outlineVariant, radius: 16, strokeWidth: active ? 1.6 : 1.2),
      child: Material(
        color: active ? scheme.primary.withValues(alpha: 0.06) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onHover: (bool value) => setState(() => _hover = value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: <Widget>[
                AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: widget.busy
                        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.onPrimaryContainer))
                        : Icon(widget.icon, size: 28, color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 14),
                UTextTitleSmall(widget.title, fontWeight: FontWeight.w700, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                UTextBodySmall(widget.subtitle, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
                if (widget.formats != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _Pill(text: widget.formats!, icon: Icons.description_outlined, background: scheme.surfaceContainerHighest, foreground: scheme.onSurfaceVariant).ltr(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius, this.strokeWidth = 1.2});

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final double inset = strokeWidth / 2;
    final Path border = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth), Radius.circular(radius)));
    for (final ui.PathMetric metric in border.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, min(d + 6, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
}
