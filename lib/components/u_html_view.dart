import "package:u/utilities.dart";

/// Signature for building a custom widget for an `<img>` found in the HTML.
typedef UHtmlImageBuilder = Widget Function(BuildContext context, String url, String? alt, double? width);

/// Read-only renderer that draws stored HTML with native Flutter widgets, so it
/// works on every platform without a WebView. It shares the parser and styling
/// used by [URichTextEditor], so what you edit is exactly what you see.
///
/// ```dart
/// UHtmlView(
///   html: post.body,
///   selectable: true,
///   onLinkTap: (String href) => ULaunch.launchURL(href),
/// )
/// ```
class UHtmlView extends StatefulWidget {
  const UHtmlView({
    required this.html,
    super.key,
    this.onLinkTap,
    this.onImageTap,
    this.onChecklistChanged,
    this.imageBuilder,
    this.selectable = false,
    this.showCodeCopyButton = true,
    this.padding = EdgeInsets.zero,
    this.textStyle,
    this.textDirection,
    this.imageHeight,
    this.scrollable = false,
  });

  final String html;

  /// Called when a link is tapped. Defaults to opening it with [ULaunch].
  final ValueChanged<String>? onLinkTap;

  /// Called when an image is tapped. Defaults to a full screen image viewer.
  final ValueChanged<String>? onImageTap;

  /// When set, checklist items become tappable and report `(index, checked)`
  /// where `index` counts checklist items from the top of the document.
  final void Function(int index, bool checked)? onChecklistChanged;

  /// Replace the default image rendering.
  final UHtmlImageBuilder? imageBuilder;

  /// Allow the user to select and copy the rendered text.
  final bool selectable;

  /// Show a copy button on code blocks.
  final bool showCodeCopyButton;

  final EdgeInsets padding;

  /// Overrides the base text style every block is derived from.
  final TextStyle? textStyle;

  final TextDirection? textDirection;

  /// Fixed height for images. Null keeps the intrinsic aspect ratio.
  final double? imageHeight;

  /// Wrap the output in its own scroll view. Leave false when already inside
  /// a scrollable.
  final bool scrollable;

  @override
  State<UHtmlView> createState() => _UHtmlViewState();
}

class _UHtmlViewState extends State<UHtmlView> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  List<UEditorBlock> _blocks = <UEditorBlock>[];

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant UHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) _rebuild();
  }

  @override
  void dispose() {
    _disposeBlocks();
    super.dispose();
  }

  void _disposeBlocks() {
    for (final UEditorBlock b in _blocks) {
      b.dispose();
    }
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _rebuild() {
    _disposeBlocks();
    _blocks = UHtmlDocument.parse(widget.html);
  }

  void _openLink(String href) {
    if (widget.onLinkTap != null) {
      widget.onLinkTap!(href);
      return;
    }
    ULaunch.launchURL(href);
  }

  void _openImage(String url) {
    if (widget.onImageTap != null) {
      widget.onImageTap!(url);
      return;
    }
    UNavigator.push(UImageViewer(fileData: FileData(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    // Recognizers are rebuilt with the spans on every frame, so clear the old ones.
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final List<Widget> children = <Widget>[];
    int checklistIndex = 0;
    int i = 0;
    while (i < _blocks.length) {
      final UEditorBlock b = _blocks[i];
      if (b.isList) {
        final UBlockType listType = b.type;
        int ordinal = 0;
        while (i < _blocks.length && _blocks[i].type == listType) {
          ordinal++;
          children.add(_listItem(_blocks[i], ordinal, listType == UBlockType.checklist ? checklistIndex++ : -1));
          i++;
        }
        continue;
      }
      children.add(_block(b));
      i++;
    }

    final Widget column = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children);
    Widget content = widget.padding == EdgeInsets.zero ? column : Padding(padding: widget.padding, child: column);
    if (widget.textDirection != null) content = Directionality(textDirection: widget.textDirection!, child: content);
    if (widget.selectable) content = SelectionArea(child: content);
    return widget.scrollable ? SingleChildScrollView(child: content) : content;
  }

  // ---- blocks --------------------------------------------------------------

  Widget _block(UEditorBlock b) {
    final EdgeInsets pad = UEditorStyles.spacing(b.type);
    switch (b.type) {
      case UBlockType.divider:
        return Padding(padding: pad, child: const Divider(thickness: 1));
      case UBlockType.image:
        return Padding(padding: pad, child: _image(b));
      case UBlockType.table:
        return Padding(padding: pad, child: _table(b.table ?? UTableData.empty()));
      case UBlockType.code:
        return Padding(padding: pad, child: _code(b));
      default:
        return Padding(
          padding: EdgeInsetsDirectional.only(top: pad.top, bottom: pad.bottom, start: b.indent * UHtmlDocument.indentStep),
          child: UEditorStyles.decorate(context, b.type, _richText(b)),
        );
    }
  }

  Widget _image(UEditorBlock b) {
    final String url = b.imageUrl ?? "";
    final Widget image = widget.imageBuilder != null
        ? widget.imageBuilder!(context, url, b.imageAlt, b.imageWidth)
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: UImage(url, width: b.imageWidth ?? double.infinity, height: widget.imageHeight, fit: b.imageWidth == null ? BoxFit.fitWidth : BoxFit.contain),
          );
    return Align(
      alignment: _alignmentOf(b.align),
      child: Column(
        children: <Widget>[
          image.onTap(() => _openImage(url)),
          if ((b.imageAlt ?? "").isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(b.imageAlt!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  Widget _code(UEditorBlock b) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Stack(
      children: <Widget>[
        UEditorStyles.decorate(context, UBlockType.code, SingleChildScrollView(scrollDirection: Axis.horizontal, child: _richText(b))),
        if ((b.language ?? "").isNotEmpty)
          PositionedDirectional(
            top: 2,
            start: 8,
            child: Text(b.language!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        if (widget.showCodeCopyButton)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: cs.onSurfaceVariant),
              tooltip: U.s.copy,
              onPressed: () => UClipboard.set(b.controller!.text, snackBar: true),
            ),
          ),
      ],
    );
  }

  Widget _table(UTableData table) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderSide side = BorderSide(color: cs.outlineVariant);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - widget.padding.horizontal - 32),
        child: Table(
          border: TableBorder(top: side, bottom: side, left: side, right: side, horizontalInside: side, verticalInside: side),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            for (int r = 0; r < table.rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: table.hasHeader && r == 0 ? cs.surfaceContainerHighest : null),
                children: <Widget>[
                  for (final String cell in table.rows[r])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(cell, style: _baseStyle(UBlockType.paragraph).copyWith(fontWeight: table.hasHeader && r == 0 ? FontWeight.bold : null)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _listItem(UEditorBlock b, int ordinal, int checklistIndex) {
    final TextStyle style = _baseStyle(b.type);
    final Widget marker = b.type == UBlockType.checklist
        ? SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: b.checked,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: widget.onChecklistChanged == null ? null : (bool? v) => widget.onChecklistChanged!(checklistIndex, v ?? false),
            ),
          )
        : Text(b.type == UBlockType.numbered ? "$ordinal." : "•", style: style);

    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8 + b.indent * UHtmlDocument.indentStep, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: marker),
          _richText(b, strike: b.type == UBlockType.checklist && b.checked).expanded(),
        ],
      ),
    );
  }

  // ---- inline --------------------------------------------------------------

  TextStyle _baseStyle(UBlockType type) {
    final TextStyle style = UEditorStyles.baseStyle(context, type);
    return widget.textStyle == null ? style : style.merge(widget.textStyle);
  }

  Widget _richText(UEditorBlock b, {bool strike = false}) {
    TextStyle base = _baseStyle(b.type);
    if (strike) base = base.copyWith(decoration: TextDecoration.lineThrough, color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Text.rich(_span(b, base), textAlign: b.align);
  }

  /// Builds the styled span for a block, attaching tap recognizers to links.
  TextSpan _span(UEditorBlock b, TextStyle base) {
    final URichTextController c = b.controller!;
    final String t = c.text;
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (t.isEmpty) return TextSpan(style: base, text: "");
    if (c.spans.isEmpty) return TextSpan(style: base, text: t);

    final List<InlineSpan> children = <InlineSpan>[];
    int runStart = 0;
    Map<UInlineAttr, Object?> current = _attrsAt(c.spans, 0);
    for (int i = 1; i <= t.length; i++) {
      final Map<UInlineAttr, Object?> next = i < t.length ? _attrsAt(c.spans, i) : current;
      if (i == t.length || !_sameAttrs(current, next)) {
        children.add(_run(t.substring(runStart, i), current, base, cs));
        runStart = i;
        current = next;
      }
    }
    return TextSpan(style: base, children: children);
  }

  InlineSpan _run(String text, Map<UInlineAttr, Object?> attrs, TextStyle base, ColorScheme cs) {
    final TextStyle style = URichTextController.resolveStyle(attrs, base, cs);
    final String? href = attrs[UInlineAttr.link] as String?;
    GestureRecognizer? recognizer;
    if (href != null) {
      final TapGestureRecognizer tap = TapGestureRecognizer()..onTap = () => _openLink(href);
      _recognizers.add(tap);
      recognizer = tap;
    }
    // Sub/superscript need a real baseline shift, which only a WidgetSpan gives.
    if (attrs.containsKey(UInlineAttr.superscript) || attrs.containsKey(UInlineAttr.subscript)) {
      final bool sup = attrs.containsKey(UInlineAttr.superscript);
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Transform.translate(
          offset: Offset(0, sup ? -(base.fontSize ?? 16) * 0.32 : (base.fontSize ?? 16) * 0.18),
          child: Text(text, style: style),
        ),
      );
    }
    return TextSpan(text: text, style: style, recognizer: recognizer, mouseCursor: href != null ? SystemMouseCursors.click : null);
  }

  Map<UInlineAttr, Object?> _attrsAt(List<UStyleSpan> spans, int i) {
    final Map<UInlineAttr, Object?> active = <UInlineAttr, Object?>{};
    for (final UStyleSpan sp in spans) {
      if (i >= sp.start && i < sp.end) active[sp.attr] = sp.value;
    }
    return active;
  }

  bool _sameAttrs(Map<UInlineAttr, Object?> a, Map<UInlineAttr, Object?> b) {
    if (a.length != b.length) return false;
    for (final UInlineAttr k in a.keys) {
      if (!b.containsKey(k) || b[k] != a[k]) return false;
    }
    return true;
  }

  AlignmentGeometry _alignmentOf(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.start:
      case TextAlign.justify:
        return AlignmentDirectional.centerStart;
    }
  }
}
