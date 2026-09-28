import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

const String _pdfAsset = "assets/docs/sample_fa_en.pdf";
const String _epubAsset = "assets/docs/sample_fa.epub";
const String _pdfUrl = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";

/// SinApp's previous (pdfrx based) annotation format, base64 of this JSON.
const String _legacyJson =
    '{"markers":[{"pageNumber":1,"color":4294198070,"range":{"pageNumber":1,"text":"مطالعه‌ی فعال","start":0,"end":0},"type":"highlight","text":""},'
    '{"pageNumber":1,"color":4280391411,"range":{"pageNumber":1,"text":"یادداشت‌برداری دستی","start":0,"end":0},"type":"text","text":"یادداشت قدیمی از نسخه‌ی قبلی"},'
    '{"pageNumber":2,"color":4283215696,"range":{"pageNumber":2,"text":"Two columns","start":0,"end":0},"type":"border","text":""}],"pageMarks":[3]}';

/// Every option of the PDF / EPUB readers, applied to whichever reader is opened.
class DocumentReaderPage extends StatefulWidget {
  const DocumentReaderPage({super.key});

  @override
  State<DocumentReaderPage> createState() => _DocumentReaderPageState();
}

class _DocumentReaderPageState extends State<DocumentReaderPage> {
  bool _secure = false;
  bool _allowCopy = true;
  bool _watermark = false;
  bool _sidebar = true;
  bool _paged = false;
  bool _night = false;
  UDocNoteDisplay _noteDisplay = UDocNoteDisplay.badge;
  UDocTextGeometry _geometry = UDocTextGeometry.auto;
  UDocSpread _spread = UDocSpread.none;
  String _lastSync = "";

  UDocWatermark? get _mark => _watermark ? const UDocWatermark(lines: <String>["کاربر نمونه", "0900 000 0000"], opacity: 0.18) : null;

  void _onSync(String data) => setState(() => _lastSync = data);

  Future<void> _openPdf({
    String? asset,
    String? url,
    String? path,
    Uint8List? bytes,
    String? title,
    String? annotationData,
    String? storageKey,
    bool persist = true,
    bool draw = false,
    bool editorTools = false,
    void Function(String data)? onChanged,
  }) => UNavigator.push<void>(
    UScaffold(
      body: UPdfViewer(
        persistAnnotations: persist,
        drawController: draw ? UDocDrawController(tool: UDocDrawTool.pen) : null,
        enableAnnotations: editorTools,
        asset: asset,
        url: url,
        filePath: path,
        bytes: bytes,
        title: title,
        showBackButton: true,
        showSidebar: _sidebar,
        allowCopy: _allowCopy,
        allowShare: _allowCopy,
        secure: _secure,
        watermark: _mark,
        noteDisplay: _noteDisplay,
        textGeometry: _geometry,
        spread: _spread,
        scrollMode: _paged ? UDocScrollMode.pagedHorizontal : UDocScrollMode.verticalContinuous,
        colorMode: _night ? UDocColorMode.night : UDocColorMode.normal,
        annotationData: annotationData,
        annotationStorageKey: storageKey,
        onAnnotationsChanged: (String data) {
          print(data);
          _onSync(data);
          onChanged?.call(data);
        },
      ),
    ),
  );

  static const String _savedKey = "demo_pdf_saved_string";

  /// The whole annotation state (highlights, notes, bookmarks, drawings, text
  /// boxes) is one string: store it anywhere and hand it back to restore.
  Future<void> _openWithSavedString() => _openPdf(
    asset: _pdfAsset,
    title: "Saved in SharedPreferences",
    persist: false,
    annotationData: ULocalStorage.getString(_savedKey),
    onChanged: (String data) => ULocalStorage.set(_savedKey, data),
  );

  Future<void> _openEpub({String? asset, String? path, Uint8List? bytes, bool draw = false}) async {
    final UEpubController controller = UEpubController();
    await UNavigator.push<void>(
      UScaffold(
        body: _EpubHost(
          controller: controller,
          paged: _paged,
          night: _night,
          child: UEpubReader(
            controller: controller,
            asset: asset,
            filePath: path,
            bytes: bytes,
            showBackButton: true,
            showSidebar: _sidebar,
            allowCopy: _allowCopy,
            allowShare: _allowCopy,
            secure: _secure,
            watermark: _mark,
            noteDisplay: _noteDisplay,
            drawController: draw ? UDocDrawController(tool: UDocDrawTool.pen) : null,
            onAnnotationsChanged: _onSync,
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _pick(String extension) async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: <String>[extension]);
    if (file == null) return;
    final String? path = kIsWeb ? null : file.path;
    final Uint8List? bytes = path == null ? await file.xFile.readAsBytes() : null;
    if (extension == "pdf") {
      await _openPdf(path: path, bytes: path == null ? bytes : null, title: file.name);
    } else {
      await _openEpub(path: path, bytes: path == null ? bytes : null);
    }
  }

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Document reader",
    intro:
        "Pure-Dart PDF and EPUB readers with highlights, underline, strike-through, squiggly, border and notes, "
        "page/position bookmarks, search, outline, thumbnails, reading themes, secure mode and watermarks. "
        "The ✎ button opens drawing: pen, highlighter, area highlight, lines, arrows, rectangles, rounded rectangles, circles/ovals "
        "(with or without a fill), text boxes you type on the page and sticky notes — all selectable, movable, resizable and saved in the same string. "
        "Persian/Arabic PDFs keep correct reading order and fall back to whole-line boxes when a font's metrics are unreliable.",
    sections: <Widget>[
      _optionsSection(),
      _pdfSection(),
      _epubSection(),
      _syncSection(),
      _apiSection(),
    ],
  );

  DemoSection _optionsSection() => DemoSection(
    title: "Reader options",
    description: "Applied to the next reader you open below.",
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            FilterChip(label: const Text("Secure (no screenshots)"), selected: _secure, onSelected: (bool value) => setState(() => _secure = value)),
            FilterChip(label: const Text("Allow copy"), selected: _allowCopy, onSelected: (bool value) => setState(() => _allowCopy = value)),
            FilterChip(label: const Text("Watermark"), selected: _watermark, onSelected: (bool value) => setState(() => _watermark = value)),
            FilterChip(label: const Text("Sidebar"), selected: _sidebar, onSelected: (bool value) => setState(() => _sidebar = value)),
            FilterChip(label: const Text("Paged"), selected: _paged, onSelected: (bool value) => setState(() => _paged = value)),
            FilterChip(label: const Text("Night"), selected: _night, onSelected: (bool value) => setState(() => _night = value)),
          ],
        ),
        const DemoLabel("Notes on the page"),
        SegmentedButton<UDocNoteDisplay>(
          segments: const <ButtonSegment<UDocNoteDisplay>>[
            ButtonSegment<UDocNoteDisplay>(value: UDocNoteDisplay.badge, label: Text("Badge")),
            ButtonSegment<UDocNoteDisplay>(value: UDocNoteDisplay.bubble, label: Text("Bubble")),
            ButtonSegment<UDocNoteDisplay>(value: UDocNoteDisplay.hidden, label: Text("Hidden")),
          ],
          selected: <UDocNoteDisplay>{_noteDisplay},
          onSelectionChanged: (Set<UDocNoteDisplay> value) => setState(() => _noteDisplay = value.first),
        ),
        const DemoLabel("PDF highlight accuracy (box = pdfrx-style whole line)"),
        SegmentedButton<UDocTextGeometry>(
          segments: const <ButtonSegment<UDocTextGeometry>>[
            ButtonSegment<UDocTextGeometry>(value: UDocTextGeometry.auto, label: Text("Auto")),
            ButtonSegment<UDocTextGeometry>(value: UDocTextGeometry.precise, label: Text("Precise")),
            ButtonSegment<UDocTextGeometry>(value: UDocTextGeometry.box, label: Text("Box")),
          ],
          selected: <UDocTextGeometry>{_geometry},
          onSelectionChanged: (Set<UDocTextGeometry> value) => setState(() => _geometry = value.first),
        ),
        const DemoLabel("PDF page layout"),
        SegmentedButton<UDocSpread>(
          segments: const <ButtonSegment<UDocSpread>>[
            ButtonSegment<UDocSpread>(value: UDocSpread.none, label: Text("Single")),
            ButtonSegment<UDocSpread>(value: UDocSpread.two, label: Text("Two")),
            ButtonSegment<UDocSpread>(value: UDocSpread.coverFirst, label: Text("Cover")),
            ButtonSegment<UDocSpread>(value: UDocSpread.auto, label: Text("Auto")),
          ],
          selected: <UDocSpread>{_spread},
          onSelectionChanged: (Set<UDocSpread> value) => setState(() => _spread = value.first),
        ),
      ],
    ),
  );

  DemoSection _pdfSection() => DemoSection(
    title: "UPdfViewer",
    description:
        "Select text (long-press, or drag with a mouse; double/triple click selects a word/line) and pick a colour and a style. "
        "Tap a markup to recolour, restyle, annotate or delete it. The side panel lists thumbnails, outline, notes, bookmarks and search results. "
        "✎ opens the drawing bar: pick a tool, colour, fill (none / light / solid / white cover), thickness, opacity, dashes and font size. "
        "Select (arrow tool) to move a shape, drag its blue corner to resize, tap a selected text box to edit it. Shift or 'Keep proportions' draws squares, circles and 45° lines.",
    code: r'''
UPdfViewer(
  asset: "assets/docs/sample_fa_en.pdf",
  allowCopy: false,               // highlight but never copy
  secure: true,                   // block screenshots / recording
  watermark: UDocWatermark(lines: <String>[user.name, user.mobile]),
  annotationData: fromServer,     // newest of server vs. local wins
  onAnnotationsChanged: (String data) => api.save(data),
  // Starts with the pen selected; drawings are part of the same string.
  drawController: UDocDrawController(tool: UDocDrawTool.pen),
)''',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(onPressed: () => unawaited(_openPdf(asset: _pdfAsset, title: "نمونه‌ی فارسی / English")), icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text("Persian + English sample")),
        FilledButton.tonalIcon(onPressed: () => unawaited(_openPdf(asset: _pdfAsset, title: "Draw & type", draw: true)), icon: const Icon(Icons.draw_rounded), label: const Text("Draw & type on pages")),
        FilledButton.tonalIcon(onPressed: () => unawaited(_openWithSavedString()), icon: const Icon(Icons.save_rounded), label: const Text("Save in SharedPreferences & restore")),
        OutlinedButton.icon(onPressed: () => unawaited(_openPdf(url: _pdfUrl, title: "dummy.pdf")), icon: const Icon(Icons.public_rounded), label: const Text("From URL")),
        OutlinedButton.icon(onPressed: () => unawaited(_pick("pdf")), icon: const Icon(Icons.folder_open_rounded), label: const Text("Open a PDF…")),
        OutlinedButton.icon(
          onPressed: () => unawaited(_openPdf(asset: _pdfAsset, title: "Legacy import", annotationData: _legacyJson.toBase64(), storageKey: "demo_legacy_${DateTime.now().millisecondsSinceEpoch}")),
          icon: const Icon(Icons.history_rounded),
          label: const Text("SinApp legacy annotations"),
        ),
        OutlinedButton.icon(onPressed: () => unawaited(UNavigator.push<void>(const UPdfEditorPage(asset: _pdfAsset))), icon: const Icon(Icons.edit_document), label: const Text("PDF editor (writes into file)")),
        OutlinedButton.icon(
          onPressed: () => unawaited(_openPdf(asset: _pdfAsset, title: "Viewer + file editor tools", editorTools: true)),
          icon: const Icon(Icons.handyman_outlined),
          label: const Text("Viewer with file-editing tools"),
        ),
      ],
    ),
  );

  DemoSection _epubSection() => DemoSection(
    title: "UEpubReader",
    description:
        "The same markup tools on reflowable text: highlights stay on the same words when you change font size or switch between scroll and paged mode. "
        "Selections spanning paragraphs become one grouped markup. Bookmarks remember the exact paragraph.",
    code: r'''
UEpubReader(
  asset: "assets/docs/sample_fa.epub",
  noteDisplay: UDocNoteDisplay.badge,
  onAnnotationsChanged: (String data) => api.save(data),
)''',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(onPressed: () => unawaited(_openEpub(asset: _epubAsset)), icon: const Icon(Icons.menu_book_rounded), label: const Text("Persian EPUB sample")),
        FilledButton.tonalIcon(onPressed: () => unawaited(_openEpub(asset: _epubAsset, draw: true)), icon: const Icon(Icons.draw_rounded), label: const Text("Draw on the EPUB")),
        OutlinedButton.icon(onPressed: () => unawaited(_pick("epub")), icon: const Icon(Icons.folder_open_rounded), label: const Text("Open an EPUB…")),
      ],
    ),
  );

  DemoSection _syncSection() => DemoSection(
    title: "Annotation sync payload",
    description: "onAnnotationsChanged receives UDocAnnotationController.export() (base64 JSON) after every change — send it to your server and pass it back as annotationData.",
    child: UContainer(
      width: double.infinity,
      radius: 10,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SelectableText(
        textDirection: TextDirection.ltr,
        _lastSync.isEmpty ? "No changes yet — open a reader and add a highlight." : "${_lastSync.length} chars\n${_decoded(_lastSync)}",
        style: const TextStyle(fontFamily: "monospace", fontSize: 11),
      ),
    ),
  );

  String _decoded(String data) {
    final Map<String, Object?>? json = UDocAnnotationController.decode(data);
    if (json == null) return data;
    final String pretty = const JsonEncoder.withIndent("  ").convert(json);
    return pretty.length > 1600 ? "${pretty.substring(0, 1600)}…" : pretty;
  }

  DemoSection _apiSection() => const DemoSection(
    title: "Building blocks",
    description: "Use the pieces directly for custom UIs.",
    code: r'''
// Shared by PDF and EPUB
final UDocAnnotationController notes = UDocAnnotationController(storageKey: "course-42");
notes.add(UDocMarkup.create(kind: UDocMarkupKind.squiggly, pageIndex: 3, color: color, rects: rects));
notes.toggleBookmark(7);
final String payload = notes.export();          // base64 JSON
notes.import(payload, merge: true);              // also accepts SinApp legacy payloads
final String md = notes.toMarkdown(title: "Chapter 1");

// Panels
UDocAnnotationsPanel(controller: notes, onOpen: (UDocMarkup m) => viewer.jumpToPage(m.pageIndex));
UDocBookmarksPanel(controller: notes, onOpen: (UDocBookmark b) => ...);

// Text geometry (per-character rects + whole-box fallback)
final UDocTextPage text = await pdfController.textPage(0);
final List<Rect> boxes = text.rectsForRange(10, 20, geometry: UDocTextGeometry.auto);''',
    child: SizedBox.shrink(),
  );
}

/// Applies initial reading mode / theme to an EPUB controller once it is ready.
class _EpubHost extends StatefulWidget {
  const _EpubHost({required this.controller, required this.paged, required this.night, required this.child});

  final UEpubController controller;
  final bool paged;
  final bool night;
  final Widget child;

  @override
  State<_EpubHost> createState() => _EpubHostState();
}

class _EpubHostState extends State<_EpubHost> {
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_apply);
  }

  void _apply() {
    if (_applied || !widget.controller.value.isReady) return;
    _applied = true;
    if (widget.paged) widget.controller.setScrollMode(UDocScrollMode.pagedHorizontal);
    if (widget.night) widget.controller.setColorMode(UDocColorMode.night);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_apply);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
