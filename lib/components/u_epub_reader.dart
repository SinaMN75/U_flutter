import "package:u/utilities.dart";

class UEpubReader extends StatefulWidget {
  const UEpubReader({
    this.filePath,
    this.bytes,
    this.url,
    this.asset,
    this.controller,
    this.initialChapter = 0,
    this.showToolbar = true,
    this.onChapterChanged,
    super.key,
  }) : assert(filePath != null || bytes != null || url != null || asset != null || controller != null, "Provide one EPUB source");

  final String? filePath;
  final Uint8List? bytes;
  final String? url;
  final String? asset;
  final UEpubController? controller;
  final int initialChapter;
  final bool showToolbar;
  final void Function(int chapterIndex)? onChapterChanged;

  @override
  State<UEpubReader> createState() => UEpubReaderState();
}

class UEpubReaderState extends State<UEpubReader> {
  late UEpubController _controller;
  bool _ownsController = false;

  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchField = TextEditingController();

  UEpubChapter? _chapter;
  PageController? _pageController;
  int _pageInChapter = 0;
  String _selectedText = "";
  bool _chromeVisible = true;
  bool _searchOpen = false;
  bool _loading = true;
  Timer? _progressTimer;

  UEpubController get controller => _controller;

  @override
  void initState() {
    super.initState();
    final UEpubController? provided = widget.controller;
    _controller = provided ?? UEpubController();
    _ownsController = provided == null;
    _controller.addListener(_onChanged);
    _scroll.addListener(_onScroll);
    unawaited(_start());
    _progressTimer = Timer.periodic(const Duration(seconds: 15), (Timer timer) => _controller.saveProgress(percent: _percent()));
  }

  Future<void> _start() async {
    await _controller.loadTypography();
    if (_ownsController) {
      await _controller.open(path: widget.filePath, url: widget.url, bytes: widget.bytes, asset: widget.asset);
    }
    if (!mounted) return;
    final int target = widget.initialChapter > 0 ? widget.initialChapter : _controller.value.pageIndex;
    await _loadChapter(target);
  }

  Future<void> _loadChapter(int index, {String? anchor}) async {
    if (_controller.pageCount == 0) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final int target = index.clamp(0, _controller.pageCount - 1);
    final UEpubChapter chapter = await _controller.chapter(target);
    if (!mounted) return;
    _controller.goToPage(target);
    widget.onChapterChanged?.call(target);
    setState(() {
      _chapter = chapter;
      _loading = false;
      _pageInChapter = 0;
      _pageController?.dispose();
      _pageController = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!_scroll.hasClients) return;
      if (anchor == null) {
        _scroll.jumpTo(0);
        return;
      }
      final int blockIndex = chapter.anchorBlock(anchor);
      if (blockIndex <= 0) {
        _scroll.jumpTo(0);
        return;
      }
      final double estimate = blockIndex * 64;
      _scroll.jumpTo(estimate.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 4) return;
  }

  double _percent() {
    if (_controller.pageCount == 0) return 0;
    final double chapterFraction = _controller.value.pageIndex / _controller.pageCount;
    if (!_scroll.hasClients || _scroll.position.maxScrollExtent <= 0) return chapterFraction;
    final double inside = (_scroll.position.pixels / _scroll.position.maxScrollExtent).clamp(0, 1).toDouble();
    return (chapterFraction + inside / _controller.pageCount).clamp(0, 1).toDouble();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.removeListener(_onChanged);
    _scroll.dispose();
    _pageController?.dispose();
    _searchField.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UDocValue value = _controller.value;
    final UDocColorMode mode = _controller.settings.colorMode;
    final Color background = mode == UDocColorMode.normal ? Theme.of(context).colorScheme.surface : UDocColorFilters.pageBackground(mode);
    if (value.state == UDocState.opening || value.state == UDocState.idle) {
      return ColoredBox(
        color: background,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (value.hasError) {
      return ColoredBox(
        color: background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 12),
                UTextBodyMedium(U.s.couldNotOpenTheDocument, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: background,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: _buildContent(background)),
          if (_controller.settings.dim > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: _controller.settings.dim)),
              ),
            ),
          if (widget.showToolbar && _chromeVisible) Positioned(left: 0, right: 0, top: 0, child: _buildToolbar(value)),
          if (widget.showToolbar && _chromeVisible) Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar(value)),
          if (_selectedText.trim().isNotEmpty) _buildSelectionBar(),
        ],
      ),
    );
  }

  Widget _buildContent(Color background) {
    final UEpubChapter? chapter = _chapter;
    if (_loading || chapter == null) return const Center(child: CircularProgressIndicator());
    final UEpubTypography typography = _controller.typography;
    final bool rtl = _controller.settings.isRtl;
    final bool fixed = _controller.book?.fixedLayout ?? false;
    final Widget body = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (fixed) return _buildFixedLayout(chapter, constraints);
        if (!_controller.settings.isPaged) {
          return ListView.builder(
            controller: _scroll,
            padding: EdgeInsets.symmetric(horizontal: typography.horizontalMargin, vertical: typography.verticalMargin + 56),
            itemCount: chapter.blocks.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == chapter.blocks.length) return _buildChapterFooter();
              return UEpubBlockView(block: chapter.blocks[index], typography: typography, colorMode: _controller.settings.colorMode, controller: _controller, onLinkTapped: _handleLink);
            },
          );
        }
        final List<UEpubPage> pages = UEpubPaginator(
          typography: typography,
          size: Size(constraints.maxWidth, constraints.maxHeight - 96),
          textScaler: MediaQuery.textScalerOf(context),
        ).paginate(chapter);
        _pageController ??= PageController(initialPage: _pageInChapter.clamp(0, pages.length - 1));
        return PageView.builder(
          controller: _pageController,
          reverse: rtl,
          itemCount: pages.length,
          onPageChanged: (int index) => setState(() => _pageInChapter = index),
          itemBuilder: (BuildContext context, int index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: typography.horizontalMargin, vertical: typography.verticalMargin + 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: pages[index].blocks
                        .map((UEpubBlock block) => UEpubBlockView(block: block, typography: typography, colorMode: _controller.settings.colorMode, controller: _controller, onLinkTapped: _handleLink))
                        .toList(),
                  ),
                ),
                if (index == pages.length - 1) _buildChapterFooter(),
              ],
            ),
          ),
        );
      },
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _chromeVisible = !_chromeVisible),
      child: SelectionArea(
        onSelectionChanged: (SelectedContent? content) => setState(() => _selectedText = content?.plainText ?? ""),
        child: Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: body),
      ),
    );
  }

  Widget _buildFixedLayout(UEpubChapter chapter, BoxConstraints constraints) {
    final UEpubBlock? image = chapter.blocks.where((UEpubBlock block) => block.kind == UEpubBlockKind.image).firstOrNull;
    if (image != null) {
      return InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: UEpubImageView(controller: _controller, href: image.imageHref ?? ""),
        ),
      );
    }
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.symmetric(horizontal: _controller.typography.horizontalMargin, vertical: _controller.typography.verticalMargin + 56),
      children: chapter.blocks
          .map((UEpubBlock block) => UEpubBlockView(block: block, typography: _controller.typography, colorMode: _controller.settings.colorMode, controller: _controller, onLinkTapped: _handleLink))
          .toList(),
    );
  }

  Widget _buildChapterFooter() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TextButton.icon(
          onPressed: _controller.value.pageIndex > 0 ? () => unawaited(_loadChapter(_controller.value.pageIndex - 1)) : null,
          icon: const Icon(Icons.chevron_left_rounded),
          label: UTextBodySmall(U.s.previous),
        ),
        TextButton.icon(
          onPressed: _controller.value.pageIndex < _controller.pageCount - 1 ? () => unawaited(_loadChapter(_controller.value.pageIndex + 1)) : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: UTextBodySmall(U.s.next),
        ),
      ],
    ),
  );

  Future<void> _handleLink(String href) async {
    final UEpubBook? book = _controller.book;
    if (book == null) return;
    if (href.startsWith("http://") || href.startsWith("https://") || href.startsWith("mailto:")) {
      await ULaunch.url(href);
      return;
    }
    final UEpubChapter? chapter = _chapter;
    final String base = chapter?.href ?? "";
    final String directory = base.contains("/") ? base.substring(0, base.lastIndexOf("/") + 1) : "";
    final String path = href.startsWith("/") ? href.substring(1) : "$directory$href";
    final int hash = path.indexOf("#");
    final String target = hash < 0 ? path : path.substring(0, hash);
    final String? anchor = hash < 0 ? null : path.substring(hash + 1);
    final int index = book.spineIndexFor(target);
    if (index < 0) {
      if (anchor != null && chapter != null) {
        final int blockIndex = chapter.anchorBlock(anchor);
        if (blockIndex > 0 && _scroll.hasClients) _scroll.jumpTo((blockIndex * 64).toDouble().clamp(0, _scroll.position.maxScrollExtent));
      }
      return;
    }
    await _loadChapter(index, anchor: anchor);
  }

  Widget _buildSelectionBar() => Positioned(
    left: 16,
    right: 16,
    bottom: 88,
    child: Center(
      child: Material(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton.icon(
                onPressed: _addHighlight,
                icon: Icon(Icons.format_color_fill_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                label: UTextBodySmall(U.s.highlight, color: Theme.of(context).colorScheme.onInverseSurface),
              ),
              TextButton.icon(
                onPressed: () => unawaited(UClipboard.set(_selectedText)),
                icon: Icon(Icons.copy_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                label: UTextBodySmall(U.s.copy, color: Theme.of(context).colorScheme.onInverseSurface),
              ),
              TextButton.icon(
                onPressed: () => unawaited(UShare.text(text: _selectedText)),
                icon: Icon(Icons.share_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                label: UTextBodySmall(U.s.share, color: Theme.of(context).colorScheme.onInverseSurface),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _addHighlight() {
    final String text = _selectedText.trim();
    if (text.isEmpty) return;
    final UEpubChapter? chapter = _chapter;
    _controller.addHighlight(
      UEpubHighlight(
        id: "${DateTime.now().microsecondsSinceEpoch}",
        position: UEpubPosition(spineIndex: chapter?.spineIndex ?? _controller.value.pageIndex, charOffset: chapter?.text.indexOf(text) ?? 0),
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    UToast.successToast(message: U.s.saved);
    setState(() => _selectedText = "");
  }

  Widget _buildToolbar(UDocValue value) => Material(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
    elevation: 2,
    child: SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(icon: const Icon(Icons.list_rounded), tooltip: U.s.contents, onPressed: () => unawaited(_openContents())),
              IconButton(icon: const Icon(Icons.bookmark_border_rounded), tooltip: U.s.highlights, onPressed: () => unawaited(_openHighlights())),
              Expanded(
                child: UTextTitleSmall(
                  _chapter?.title.isNotEmpty == true ? _chapter!.title : value.metadata.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded), tooltip: U.s.search, onPressed: () => setState(() => _searchOpen = !_searchOpen)),
              IconButton(icon: const Icon(Icons.text_fields_rounded), tooltip: U.s.readingMode, onPressed: () => unawaited(_openSettings())),
            ],
          ),
          if (_searchOpen) _buildSearchBar(value),
        ],
      ),
    ),
  );

  Widget _buildSearchBar(UDocValue value) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchField,
            autofocus: true,
            decoration: InputDecoration(isDense: true, hintText: U.s.search, border: const OutlineInputBorder()),
            onSubmitted: (String query) => unawaited(_runSearch(query)),
          ),
        ),
        const SizedBox(width: 8),
        if (value.isSearching) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        if (!value.isSearching && value.searchHits.isNotEmpty) TextButton(onPressed: () => unawaited(_openSearchResults()), child: UTextBodySmall("${value.searchHits.length}")),
      ],
    ),
  );

  Future<void> _runSearch(String query) async {
    await _controller.search(query);
    if (mounted && _controller.value.searchHits.isNotEmpty) await _openSearchResults();
  }

  Future<void> _openSearchResults() async {
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: <Widget>[
            Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.searchResults)),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.value.searchHits.length,
                itemBuilder: (BuildContext context, int index) {
                  final UDocSearchHit hit = _controller.value.searchHits[index];
                  return ListTile(
                    dense: true,
                    title: UTextBodySmall(hit.snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: UTextBodySmall("${U.s.chapter} ${hit.pageIndex + 1}"),
                    onTap: () {
                      UNavigator.back<void>();
                      unawaited(_loadChapter(hit.pageIndex));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(UDocValue value) => Material(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
    elevation: 2,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: <Widget>[
            UTextBodySmall("${(_percent() * 100).round()}%"),
            Expanded(
              child: Slider(
                value: value.pageCount <= 1 ? 0 : value.pageIndex.toDouble().clamp(0, (value.pageCount - 1).toDouble()),
                max: value.pageCount <= 1 ? 1 : (value.pageCount - 1).toDouble(),
                onChanged: (double next) => unawaited(_loadChapter(next.round())),
              ),
            ),
            UTextBodySmall("${value.pageIndex + 1}/${value.pageCount}"),
          ],
        ),
      ),
    ),
  );

  Future<void> _openContents() async {
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: <Widget>[
            Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.contents)),
            Expanded(
              child: _controller.outline.isEmpty
                  ? ListView.builder(
                      itemCount: _controller.pageCount,
                      itemBuilder: (BuildContext context, int index) => ListTile(
                        dense: true,
                        title: UTextBodyMedium("${U.s.chapter} ${index + 1}"),
                        onTap: () {
                          UNavigator.back<void>();
                          unawaited(_loadChapter(index));
                        },
                      ),
                    )
                  : ListView(children: _buildOutline(_controller.outline, 0)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOutline(List<UDocOutlineNode> nodes, int depth) {
    final List<Widget> widgets = <Widget>[];
    for (final UDocOutlineNode node in nodes) {
      widgets.add(
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 16 + depth * 16, right: 16),
          title: UTextBodyMedium(node.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () {
            UNavigator.back<void>();
            final UDocDestination? destination = node.destination;
            if (destination != null) unawaited(_loadChapter(destination.pageIndex, anchor: destination.anchor));
          },
        ),
      );
      if (node.hasChildren) widgets.addAll(_buildOutline(node.children, depth + 1));
    }
    return widgets;
  }

  Future<void> _openHighlights() async {
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: <Widget>[
            Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.highlights)),
            Expanded(
              child: _controller.highlights.isEmpty
                  ? Center(child: UTextBodyMedium(U.s.noResults))
                  : ListView.builder(
                      itemCount: _controller.highlights.length,
                      itemBuilder: (BuildContext context, int index) {
                        final UEpubHighlight highlight = _controller.highlights[index];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: Color(highlight.color), shape: BoxShape.circle),
                          ),
                          title: UTextBodySmall(highlight.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                          subtitle: UTextBodySmall("${U.s.chapter} ${highlight.position.spineIndex + 1}"),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18), onPressed: () => _controller.removeHighlight(highlight.id)),
                          onTap: () {
                            UNavigator.back<void>();
                            unawaited(_loadChapter(highlight.position.spineIndex));
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await UNavigator.bottomSheet<void>(UEpubSettingsPanel(controller: _controller, onChanged: () => setState(() {})));
    if (mounted) setState(() {});
  }
}

class UEpubBlockView extends StatelessWidget {
  const UEpubBlockView({required this.block, required this.typography, required this.colorMode, required this.controller, required this.onLinkTapped, super.key});

  final UEpubBlock block;
  final UEpubTypography typography;
  final UDocColorMode colorMode;
  final UEpubController controller;
  final Future<void> Function(String href) onLinkTapped;

  Color get _foreground {
    switch (colorMode) {
      case UDocColorMode.night:
        return const Color(0xFFE6E6E6);
      case UDocColorMode.sepia:
        return const Color(0xFF3E3226);
      case UDocColorMode.highContrast:
        return const Color(0xFF000000);
      case UDocColorMode.grayscale:
      case UDocColorMode.custom:
      case UDocColorMode.normal:
        return const Color(0xFF1A1A1A);
    }
  }

  double get _headingScale {
    switch (block.level) {
      case 1:
        return 1.7;
      case 2:
        return 1.45;
      case 3:
        return 1.28;
      case 4:
        return 1.15;
      case 5:
        return 1.08;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (block.kind == UEpubBlockKind.rule) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: block.marginTop),
        child: Divider(color: _foreground.withValues(alpha: 0.3)),
      );
    }
    if (block.kind == UEpubBlockKind.image) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: block.marginTop),
        child: UEpubImageView(controller: controller, href: block.imageHref ?? ""),
      );
    }
    if (block.kind == UEpubBlockKind.tableRow) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: block.marginTop),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.cells
              .map(
                (List<UEpubSpan> cell) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(border: Border.all(color: _foreground.withValues(alpha: 0.25))),
                    child: Text(
                      cell.map((UEpubSpan span) => span.text).join(),
                      style: TextStyle(fontSize: typography.baseFontSize * 0.92, color: _foreground, height: typography.lineHeight),
                      textDirection: block.rtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    if (block.spans.isEmpty) return const SizedBox.shrink();
    final double base = typography.baseFontSize * (block.kind == UEpubBlockKind.heading ? _headingScale : 1);
    final TextAlign align = block.align ?? (block.kind == UEpubBlockKind.heading ? TextAlign.start : (typography.justify ? TextAlign.justify : TextAlign.start));
    final List<InlineSpan> spans = <InlineSpan>[];
    for (final UEpubSpan span in block.spans) {
      final TextStyle style = TextStyle(
        fontSize: base * span.sizeFactor * (span.superscript || span.subscript ? 0.72 : 1),
        fontWeight: span.bold || block.kind == UEpubBlockKind.heading ? FontWeight.w700 : FontWeight.w400,
        fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
        decoration: span.underline ? TextDecoration.underline : (span.strike ? TextDecoration.lineThrough : TextDecoration.none),
        color: span.href != null ? Theme.of(context).colorScheme.primary : (span.color ?? _foreground),
        backgroundColor: span.background,
        height: typography.lineHeight,
        letterSpacing: typography.letterSpacing,
        wordSpacing: typography.wordSpacing,
        fontFamily: typography.fontFamily,
        fontFeatures: span.monospace ? const <FontFeature>[FontFeature.tabularFigures()] : null,
      );
      final String? href = span.href;
      if (href != null) {
        spans.add(
          TextSpan(
            text: span.text,
            style: style,
            recognizer: TapGestureRecognizer()..onTap = () => unawaited(onLinkTapped(href)),
          ),
        );
        continue;
      }
      spans.add(TextSpan(text: span.text, style: style));
    }
    final Widget text = Text.rich(
      TextSpan(children: spans),
      textAlign: align,
      textDirection: block.rtl ? TextDirection.rtl : TextDirection.ltr,
    );
    Widget content = text;
    if (block.kind == UEpubBlockKind.listItem) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8, top: 2),
            child: UTextBodyMedium(block.listMarker, color: _foreground),
          ),
          Expanded(child: text),
        ],
      );
    }
    if (block.kind == UEpubBlockKind.blockquote) {
      content = Container(
        padding: const EdgeInsets.only(left: 12, right: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: _foreground.withValues(alpha: 0.35), width: 3)),
        ),
        child: text,
      );
    }
    if (block.kind == UEpubBlockKind.preformatted) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        color: _foreground.withValues(alpha: 0.06),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: text),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: block.marginTop, bottom: block.marginBottom + typography.paragraphSpacing / 2, left: block.indent > 0 ? block.indent : 0),
      child: content,
    );
  }
}

class UEpubImageView extends StatefulWidget {
  const UEpubImageView({required this.controller, required this.href, super.key});

  final UEpubController controller;
  final String href;

  @override
  State<UEpubImageView> createState() => _UEpubImageViewState();
}

class _UEpubImageViewState extends State<UEpubImageView> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final Uint8List? bytes = await widget.controller.image(widget.href);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _failed = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final Uint8List? bytes = _bytes;
    if (bytes == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (widget.href.toLowerCase().endsWith(".svg")) return SvgPicture.memory(bytes);
    return Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (BuildContext context, Object error, StackTrace? stack) => const SizedBox.shrink());
  }
}

class UEpubSettingsPanel extends StatefulWidget {
  const UEpubSettingsPanel({required this.controller, required this.onChanged, super.key});

  final UEpubController controller;
  final VoidCallback onChanged;

  @override
  State<UEpubSettingsPanel> createState() => _UEpubSettingsPanelState();
}

class _UEpubSettingsPanelState extends State<UEpubSettingsPanel> {
  void _apply(UEpubTypography typography) {
    widget.controller.setTypography(typography);
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final UEpubTypography typography = widget.controller.typography;
    final UDocViewSettings settings = widget.controller.settings;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleMedium(U.s.fontSize),
            Slider(
              value: typography.fontScale,
              min: 0.7,
              max: 2.4,
              onChanged: (double next) => _apply(typography.copyWith(fontScale: next)),
            ),
            UTextTitleMedium(U.s.lineSpacing),
            Slider(
              value: typography.lineHeight,
              min: 1.1,
              max: 2.4,
              onChanged: (double next) => _apply(typography.copyWith(lineHeight: next)),
            ),
            UTextTitleMedium(U.s.margins),
            Slider(
              value: typography.horizontalMargin,
              max: 64,
              onChanged: (double next) => _apply(typography.copyWith(horizontalMargin: next)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: typography.justify,
              title: UTextBodyMedium(U.s.justify),
              onChanged: (bool next) => _apply(typography.copyWith(justify: next)),
            ),
            const SizedBox(height: 8),
            UTextTitleMedium(U.s.readingMode),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocScrollMode>[UDocScrollMode.verticalContinuous, UDocScrollMode.pagedHorizontal]
                  .map(
                    (UDocScrollMode mode) => ChoiceChip(
                      selected: settings.scrollMode == mode,
                      label: UTextBodySmall(mode == UDocScrollMode.verticalContinuous ? U.s.continuous : U.s.paged),
                      onSelected: (bool _) {
                        widget.controller.setScrollMode(mode);
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            UTextTitleMedium(U.s.theme),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocColorMode>[UDocColorMode.normal, UDocColorMode.night, UDocColorMode.sepia, UDocColorMode.highContrast]
                  .map(
                    (UDocColorMode mode) => ChoiceChip(
                      selected: settings.colorMode == mode,
                      label: UTextBodySmall(_label(mode)),
                      onSelected: (bool _) {
                        widget.controller.setColorMode(mode);
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            UTextTitleMedium(U.s.pageDirection),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocDirection>[UDocDirection.ltr, UDocDirection.rtl]
                  .map(
                    (UDocDirection direction) => ChoiceChip(
                      selected: settings.direction == direction,
                      label: UTextBodySmall(direction == UDocDirection.rtl ? U.s.rightToLeft : U.s.leftToRight),
                      onSelected: (bool _) {
                        widget.controller.setDirection(direction);
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            UTextTitleMedium(U.s.brightness),
            Slider(
              value: 1 - settings.dim,
              onChanged: (double next) {
                widget.controller.setDim(1 - next);
                widget.onChanged();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  String _label(UDocColorMode mode) {
    switch (mode) {
      case UDocColorMode.normal:
        return U.s.normal;
      case UDocColorMode.night:
        return U.s.night;
      case UDocColorMode.sepia:
        return U.s.sepia;
      case UDocColorMode.grayscale:
        return U.s.grayscale;
      case UDocColorMode.highContrast:
        return U.s.highContrast;
      case UDocColorMode.custom:
        return U.s.custom;
    }
  }
}

abstract class UEpub {
  static Future<void> show({String? filePath, Uint8List? bytes, String? url, String? asset, int initialChapter = 0}) => UNavigator.push<void>(
    UScaffold(
      body: UEpubReader(filePath: filePath, bytes: bytes, url: url, asset: asset, initialChapter: initialChapter),
    ),
  );

  static Future<UDocMetadata?> info({String? filePath, Uint8List? bytes, String? url}) async {
    try {
      final UEpubBook book = await UEpubBook.open(path: filePath, bytes: bytes, url: url);
      final UDocMetadata metadata = book.metadata;
      await book.close();
      return metadata;
    } on Object {
      return null;
    }
  }

  static Future<Uint8List?> cover({String? filePath, Uint8List? bytes, String? url}) async {
    try {
      final UEpubBook book = await UEpubBook.open(path: filePath, bytes: bytes, url: url);
      final String? href = book.coverHref;
      final Uint8List? data = href == null ? null : await book.resource(href);
      await book.close();
      return data == null || data.isEmpty ? null : data;
    } on Object {
      return null;
    }
  }

  static Future<String> extractText({String? filePath, Uint8List? bytes, String? url}) async {
    final UEpubBook book = await UEpubBook.open(path: filePath, bytes: bytes, url: url);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < book.chapterCount; i++) {
      buffer.writeln((await book.chapter(i)).text);
    }
    await book.close();
    return buffer.toString();
  }
}
