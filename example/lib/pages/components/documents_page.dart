import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// PDF viewer/editor building blocks, EPUB building blocks and the rich text editor, on the bundled sample files.
class DocumentsComponentsPage extends StatefulWidget {
  const DocumentsComponentsPage({super.key});

  @override
  State<DocumentsComponentsPage> createState() => _DocumentsComponentsPageState();
}

class _DocumentsComponentsPageState extends State<DocumentsComponentsPage> {
  static const String _pdfAsset = "assets/docs/sample_fa_en.pdf";
  static const String _epubAsset = "assets/docs/sample_fa.epub";
  static const String _html = "<h2>Title</h2><p>Hello <b>bold</b> and <i>italic</i> <a href='https://x.com'>link</a>.</p><ul><li>one</li><li>two</li></ul>";

  final UPdfController _pdf = UPdfController();
  late final UPdfEditController _edit = UPdfEditController(viewer: _pdf);
  final UEpubController _epub = UEpubController();
  final URichTextController _rich = URichTextController(text: "Hello rich text");
  UEpubChapter? _chapter;
  bool _pdfReady = false;
  bool _epubReady = false;

  @override
  void initState() {
    super.initState();
    _pdf.open(asset: _pdfAsset).then((_) => mounted ? setState(() => _pdfReady = true) : null);
    _epub.open(asset: _epubAsset).then((_) async {
      final UEpubChapter c = await _epub.chapter(0);
      if (!mounted) return;
      setState(() {
        _chapter = c;
        _epubReady = true;
      });
    });
  }

  @override
  void dispose() {
    _pdf.dispose();
    _epub.dispose();
    _rich.dispose();
    super.dispose();
  }

  Future<Object?> _needPdf(Future<Object?> Function() run) async => _pdfReady ? run() : "PDF still loading";

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Documents",
    intro: "Pure Dart PDF/EPUB engines: every platform, web included. The full readers are in Showcases → Document reader.",
    children: <Widget>[
      DemoGroup("PDF shortcuts", <Widget>[
        Fn("UPdf.show(asset: …)", () => UPdf.show(asset: _pdfAsset, title: "Sample")),
        Fn(
          "UPdf.open(asset: …, secure: true, watermark: …)",
          () => UPdf.open(
            asset: _pdfAsset,
            secure: true,
            watermark: const UDocWatermark(lines: <String>["user@example.com"]),
          ),
        ),
        Fn("UPdf.info(bytes: …)", () async => (await UPdf.info(bytes: (await rootBundle.load(_pdfAsset)).buffer.asUint8List()))?.title),
        Fn("UPdf.extractText(bytes: …)", () async => (await UPdf.extractText(bytes: (await rootBundle.load(_pdfAsset)).buffer.asUint8List())).maxLength(max: 120)),
      ]),
      DemoGroup("PDF building blocks", <Widget>[
        if (_pdfReady) ...<Widget>[
          Demo(
            "UPdfPageView(controller: …, pageIndex: 0, displayScale: 1)",
            child: SizedBox(height: 300, child: UPdfPageView(controller: _pdf, pageIndex: 0, displayScale: 1)),
          ),
          Demo(
            "UPdfThumbnail(controller: …, pageIndex: 0)",
            child: SizedBox(height: 120, child: UPdfThumbnail(controller: _pdf, pageIndex: 0)),
          ),
          Demo(
            "UPdfThumbnailPanel(controller: …)",
            child: SizedBox(
              height: 240,
              child: UPdfThumbnailPanel(
                controller: _pdf,
                currentPage: 0,
                onSelected: (int i) => UToast.toast(message: "page $i"),
              ),
            ),
          ),
          Demo(
            "UPdfOutlinePanel(controller: …)",
            child: SizedBox(
              height: 160,
              child: UPdfOutlinePanel(
                controller: _pdf,
                onSelected: (UDocDestination d) => UToast.toast(message: "page ${d.pageIndex}"),
              ),
            ),
          ),
          Demo(
            "UPdfSettingsPanel(controller: …)",
            child: SizedBox(
              height: 300,
              child: UPdfSettingsPanel(controller: _pdf, onChanged: () {}),
            ),
          ),
          Demo(
            "UPdfPageManager(viewer: …, editor: …)",
            child: SizedBox(
              height: 260,
              child: UPdfPageManager(viewer: _pdf, editor: _edit),
            ),
          ),
          Demo(
            "UPdfPageManagerPanel / UPdfAnnotationsPanel / UPdfDocumentToolsPanel",
            child: SizedBox(
              height: 300,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: <Widget>[
                    const TabBar(
                      tabs: <Widget>[
                        Tab(text: "Pages"),
                        Tab(text: "Notes"),
                        Tab(text: "Tools"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          UPdfPageManagerPanel(viewer: _pdf, editor: _edit),
                          UPdfAnnotationsPanel(
                            editor: _edit,
                            onJump: (int i) => UToast.toast(message: "page $i"),
                          ),
                          UPdfDocumentToolsPanel(viewer: _pdf, editor: _edit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else
          const Demo("loading sample.pdf…", child: LinearProgressIndicator()),
        Fn(
          "UNavigator.push(UPdfEditorPage(asset: …))",
          () => UNavigator.push<void>(
            UPdfEditorPage(
              asset: _pdfAsset,
              author: "Demo",
              onSaved: (String p) => UToast.success(message: p),
            ),
          ),
        ),
      ]),
      DemoGroup("PDF editing from code (UPdfEditController)", <Widget>[
        Fn(
          "attach() / setTool / setColor / setInkColor / setStrokeWidth / setOpacity / setFontSize / setAuthor",
          () => _needPdf(() async {
            _edit.attach();
            _edit.setTool(UPdfTool.highlight);
            _edit.setColor(Colors.yellow);
            _edit.setInkColor(Colors.blue);
            _edit.setStrokeWidth(3);
            _edit.setOpacity(0.5);
            _edit.setFontSize(12);
            _edit.setAuthor("Demo");
            return <Object?>[
              _edit.tool,
              _edit.color,
              _edit.inkColor,
              _edit.strokeWidth,
              _edit.opacity,
              _edit.fontSize,
              _edit.author,
              _edit.isDrawing,
              _edit.hasChanges,
              _edit.canUndo,
              _edit.edit != null,
            ];
          }),
        ),
        Fn(
          "devicePointToPdf / deviceRectToPdf",
          () => _needPdf(() async {
            final UDocPageInfo info = _pdf.pageInfo(0);
            return <Object>[_edit.devicePointToPdf(info, const Offset(10, 10)), _edit.deviceRectToPdf(info, const Rect.fromLTWH(0, 0, 50, 20))];
          }),
        ),
        Fn(
          "beginStroke / extendStroke / liveStroke / endStroke (ink)",
          () => _needPdf(() async {
            _edit.setTool(UPdfTool.ink);
            _edit.beginStroke(0, const Offset(40, 40));
            _edit.extendStroke(0, const Offset(120, 80));
            final int points = _edit.liveStroke(0).length;
            await _edit.endStroke(0);
            return points;
          }),
        ),
        Fn(
          "addNote / addTextBox / annotationsOn / allAnnotations / annotationAt",
          () => _needPdf(() async {
            await _edit.addNote(0, const Offset(60, 60), "Sticky note");
            await _edit.addTextBox(0, const Offset(80, 140), "Text box");
            final List<UPdfAnnotationInfo> page = await _edit.annotationsOn(0);
            return <Object?>[page.length, (await _edit.allAnnotations()).length, (await _edit.annotationAt(0, const Offset(60, 60)))?.subtype];
          }),
        ),
        Fn(
          "annotateSelection(selection, textPage)",
          () => _needPdf(() async {
            final UDocTextPage text = await _pdf.textPage(0);
            return _edit.annotateSelection(const UDocSelection(pageIndex: 0, start: 0, end: 10, text: ""), text);
          }),
        ),
        Fn(
          "updateAnnotation / deleteAnnotation / eraseAt / undo",
          () => _needPdf(() async {
            final List<UPdfAnnotationInfo> all = await _edit.annotationsOn(0);
            if (all.isEmpty) return "add a note first";
            await _edit.updateAnnotation(0, all.first.objectNumber, contents: "Updated");
            await _edit.deleteAnnotation(0, all.first.objectNumber);
            await _edit.eraseAt(0, const Offset(80, 140));
            await _edit.undo();
            return (await _edit.annotationsOn(0)).length;
          }),
        ),
        Fn(
          "rotatePage / duplicatePage / movePage / insertBlankPage / deletePage",
          () => _needPdf(() async => <bool>[await _edit.rotatePage(0, 90), await _edit.duplicatePage(0), await _edit.movePage(1, 0), await _edit.insertBlankPage(0), await _edit.deletePage(0)]),
        ),
        Fn(
          "applyRedactions / applyPendingRedactions / flatten",
          () => _needPdf(
            () async => <int>[
              await _edit.applyRedactions(0, const <Rect>[Rect.fromLTWH(20, 20, 100, 20)]),
              await _edit.applyPendingRedactions(),
              await _edit.flatten(),
            ],
          ),
        ),
        Fn(
          "addWatermark / addPageNumbers / setMetadata / setCrop",
          () => _needPdf(
            () async => <bool>[
              await _edit.addWatermark("CONFIDENTIAL"),
              await _edit.addPageNumbers(),
              await _edit.setMetadata(const UDocMetadata(title: "Edited sample")),
              await _edit.setCrop(0, const Rect.fromLTWH(0, 0, 500, 700)),
            ],
          ),
        ),
        Fn(
          "mergeFile(bytes) / exportPages([0])",
          () => _needPdf(() async {
            final Uint8List bytes = (await rootBundle.load(_pdfAsset)).buffer.asUint8List();
            return <Object?>[
              await _edit.mergeFile(bytes),
              (await _edit.exportPages(<int>[0]))?.length.toBKMG(),
            ];
          }),
        ),
        Fn(
          "saveToBytes() / saveTo(path) / saveOptimized(path)",
          () => _needPdf(() async {
            final Uint8List? bytes = await _edit.saveToBytes();
            if (kIsWeb) return bytes?.length.toBKMG();
            final String dir = (await getTemporaryDirectory()).path;
            return <Object?>[bytes?.length.toBKMG(), await _edit.saveTo("$dir/edited.pdf"), await _edit.saveOptimized("$dir/small.pdf")];
          }),
        ),
        Fn(
          "UPdfFormPanel(edit: …, fields: …)",
          () => _needPdf(() async {
            final UPdfEdit? edit = _edit.edit;
            if (edit == null) return "run attach() first";
            await UNavigator.bottomSheet<void>(
              SizedBox(
                height: 400,
                child: UPdfFormPanel(edit: edit, fields: const <UPdfFormField>[], onChanged: (int page) {}),
              ),
            );
            return "shown";
          }),
        ),
      ]),
      DemoGroup("EPUB", <Widget>[
        Fn("UEpub.show(asset: …)", () => UEpub.show(asset: _epubAsset, title: "Sample")),
        Fn("UEpub.info / cover / extractText (bytes)", () async {
          final Uint8List bytes = (await rootBundle.load(_epubAsset)).buffer.asUint8List();
          return <Object?>[(await UEpub.info(bytes: bytes))?.title, (await UEpub.cover(bytes: bytes))?.length, (await UEpub.extractText(bytes: bytes)).length];
        }),
        if (_epubReady && _chapter != null && _chapter!.blocks.isNotEmpty) ...<Widget>[
          Demo(
            "UEpubBlockView(block: …, typography: …, colorMode: …, controller: …)",
            child: UEpubBlockView(block: _chapter!.blocks.first, typography: const UEpubTypography(), colorMode: UDocColorMode.normal, controller: _epub, onLinkTapped: (String href) async {}),
          ),
          Demo(
            "UEpubSettingsPanel(controller: …)",
            child: SizedBox(
              height: 300,
              child: UEpubSettingsPanel(controller: _epub, onChanged: () {}),
            ),
          ),
          Demo(
            "UEpubImageView(controller: …, href: …)",
            child: Builder(
              builder: (BuildContext c) {
                final String? href = _epub.book?.resourcesByHref.keys.firstWhereOrNull((String h) => RegExp(r"\.(png|jpe?g|gif|webp|svg)$", caseSensitive: false).hasMatch(h));
                return href == null
                    ? const Text("this book has no images")
                    : SizedBox(
                        height: 160,
                        child: UEpubImageView(controller: _epub, href: href),
                      );
              },
            ),
          ),
          Builder(
            builder: (BuildContext c) => Fn("UEpubTextStyler.foreground / background / headingScale / align / direction", () {
              final UEpubBlock b = _chapter!.blocks.first;
              return <Object>[
                UEpubTextStyler.foreground(c, UDocColorMode.sepia),
                UEpubTextStyler.background(c, UDocColorMode.night),
                UEpubTextStyler.headingScale(1),
                UEpubTextStyler.align(b, const UEpubTypography()),
                UEpubTextStyler.direction(b),
              ];
            }),
          ),
          Builder(
            builder: (BuildContext c) => Fn("UEpubTextStyler.span / painter / lineRects", () {
              final UEpubBlock b = _chapter!.blocks.first;
              final TextSpan span = UEpubTextStyler.span(c, b, const UEpubTypography(), UDocColorMode.normal);
              final TextPainter p = UEpubTextStyler.painter(c, b, const UEpubTypography(), UDocColorMode.normal, 300);
              return <Object>[span.toPlainText().maxLength(max: 40), p.height.round(), UEpubTextStyler.lineRects(p, b.text, 0, min(5, b.text.length), fontSize: 16).length];
            }),
          ),
        ] else
          const Demo("loading sample.epub…", child: LinearProgressIndicator()),
      ]),
      DemoGroup("Rich text editor", <Widget>[
        Fn("await URichTextEditor.open(initialHtml: …)", () async => (await URichTextEditor.open(initialHtml: _html))?.maxLength(max: 120)),
        Demo(
          "URichTextEditorField(content: …, onSubmit: …)",
          child: URichTextEditorField(
            content: _html,
            onSubmit: (String html) => UToast.toast(message: "${UHtmlDocument.wordCount(html)} words"),
          ),
        ),
        Demo(
          "URichTextEditor(initialHtml: …) inline",
          child: const SizedBox(height: 360, child: URichTextEditor(initialHtml: _html)),
        ),
        Fn("UHtmlDocument.parse / serialize / toPlainText / wordCount / characterCount / readingMinutes", () {
          final List<UEditorBlock> blocks = UHtmlDocument.parse(_html);
          return <Object>[
            blocks.length,
            UHtmlDocument.serialize(blocks).length,
            UHtmlDocument.toPlainText(_html),
            UHtmlDocument.wordCount(_html),
            UHtmlDocument.characterCount(_html),
            UHtmlDocument.readingMinutes(_html),
          ];
        }, auto: true),
        Fn(
          'UHtmlDocument.escapeHtml("<b>") / escapeAttr / parseCssColor("#ff0000")',
          () => <Object?>[UHtmlDocument.escapeHtml("<b>"), UHtmlDocument.escapeAttr('"q"'), UHtmlDocument.parseCssColor("#ff0000")],
          auto: true,
        ),
        Fn("URichTextController: select all → toggleAttribute(bold) / applyValue / activeAttributes / activeValue / activeLink", () {
          _rich.selection = TextSelection(baseOffset: 0, extentOffset: _rich.text.length);
          _rich.toggleAttribute(UInlineAttr.bold);
          _rich.applyValue(UInlineAttr.color, 0xFFD32F2F);
          _rich.applyValue(UInlineAttr.link, "https://x.com");
          return <Object?>[_rich.activeAttributes(), _rich.activeValue(UInlineAttr.color), _rich.activeLink()];
        }),
        Fn("UHtmlDocument.inlineHtml(controller) / inlineHtmlOf(text, spans)", () => <String>[UHtmlDocument.inlineHtml(_rich), UHtmlDocument.inlineHtmlOf(_rich.text, _rich.snapshotSpans())]),
        Fn("styleAt / resolveStyle / removeAttr / clearFormatting / normalize / setContent", () {
          final ColorScheme cs = Theme.of(context).colorScheme;
          final TextStyle at = _rich.styleAt(0, const TextStyle(), cs);
          final TextStyle resolved = URichTextController.resolveStyle(<UInlineAttr, Object?>{UInlineAttr.italic: null}, const TextStyle(), cs);
          _rich.removeAttr(UInlineAttr.link, 0, _rich.text.length);
          _rich.clearFormatting();
          _rich.normalize();
          _rich.setContent("Fresh text", <UStyleSpan>[UStyleSpan(start: 0, end: 5, attr: UInlineAttr.bold)]);
          return <Object?>[at.fontWeight, resolved.fontStyle, _rich.spans.length];
        }),
        Fn("onBeforeTextChange / mapOffsetStart / mapOffsetEnd", () {
          _rich.onBeforeTextChange("Fresh text", "Fresh new text");
          return <int>[URichTextController.mapOffsetStart(8, 6, 6, 4), URichTextController.mapOffsetEnd(8, 6, 6, 4)];
        }),
        Builder(
          builder: (BuildContext c) => Fn(
            "UEditorStyles.baseStyle / spacing / label / decorate",
            () => <Object>[
              UEditorStyles.baseStyle(c, UBlockType.h1).fontSize ?? 0,
              UEditorStyles.spacing(UBlockType.quote),
              UEditorStyles.label(UBlockType.h2),
              UEditorStyles.decorate(c, UBlockType.quote, const Text("q")).runtimeType,
            ],
          ),
        ),
        Demo(
          "UEditorToolButton / UEditorToolSeparator / UEditorDropdown",
          child: URow(
            children: <Widget>[
              UEditorToolButton(icon: Icons.format_bold, tooltip: "Bold", active: true, onTap: () {}),
              const UEditorToolSeparator(),
              UEditorDropdown<int>(
                label: "Size",
                items: <UEditorMenuEntry<int>>[
                  UEditorMenuEntry<int>(value: 14, label: "14"),
                  UEditorMenuEntry<int>(value: 18, label: "18"),
                ],
                onSelected: (int v) => UToast.toast(message: "$v"),
              ),
            ],
          ),
        ),
        Builder(builder: (BuildContext c) => Fn("UEditorDialogs.pickColor(context: …)", () => UEditorDialogs.pickColor(context: c))),
        Fn(
          "UEditorDialogs.editLink / insertTable / findReplace",
          () async => <Object?>[await UEditorDialogs.editLink(), (await UEditorDialogs.insertTable())?.rowCount, (await UEditorDialogs.findReplace())?.find],
        ),
        Fn("UEditorDialogs.htmlSource(html: …) / documentInfo(html: …)", () async {
          final String? html = await UEditorDialogs.htmlSource(html: _html);
          await UEditorDialogs.documentInfo(html: html ?? _html);
          return html?.length;
        }),
      ]),
    ],
  );
}
