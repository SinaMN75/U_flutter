import "package:u/utilities.dart";

/// A self-contained, cross-platform rich text editor that produces and consumes
/// HTML. No third-party editor packages are used.
///
/// Public API:
///  * [URichTextEditor] – embeddable block editor widget.
///  * [URichTextEditor.open] – push a full-screen editor and get the HTML back.
///  * [UHtmlDocument] – blocks ⇄ HTML serialize/parse plus HTML helpers.
///  * [URichTextController] / [UEditorBlock] / [UTableData] – the document model.
///  * [UEditorStyles] – styling shared with the read-only [UHtmlView].
///
/// The read-only renderer lives in `u_html_view.dart`.

// =============================================================================
//  MODEL
// =============================================================================

/// Inline formatting attributes that can be applied to a range of characters.
enum UInlineAttr { bold, italic, underline, strikethrough, code, superscript, subscript, color, highlight, fontSize, fontFamily, link }

/// Block level types the editor supports. All values except [UBlockType.image],
/// [UBlockType.divider] and [UBlockType.table] are text blocks that own a
/// [URichTextController].
enum UBlockType { paragraph, h1, h2, h3, h4, h5, h6, quote, bulleted, numbered, checklist, code, image, divider, table }

/// The attributes that behave as on/off toggles (no payload).
const List<UInlineAttr> uBooleanInlineAttrs = <UInlineAttr>[
  UInlineAttr.bold,
  UInlineAttr.italic,
  UInlineAttr.underline,
  UInlineAttr.strikethrough,
  UInlineAttr.code,
  UInlineAttr.superscript,
  UInlineAttr.subscript,
];

/// A single inline style span over the range [start, end) of a text block.
/// [value] carries the payload for value-attributes: `int` (ARGB) for
/// [UInlineAttr.color] and [UInlineAttr.highlight], `double` for
/// [UInlineAttr.fontSize], and `String` for [UInlineAttr.fontFamily] (family
/// name) and [UInlineAttr.link] (href). It is null for boolean attributes.
class UStyleSpan {
  UStyleSpan({required this.start, required this.end, required this.attr, this.value});

  int start;
  int end;
  final UInlineAttr attr;
  final Object? value;

  bool get isBoolean => value == null;

  UStyleSpan copy() => UStyleSpan(start: start, end: end, attr: attr, value: value);
}

/// A [TextEditingController] that keeps a list of [UStyleSpan]s in sync with
/// text edits and renders them via [buildTextSpan]. It survives
/// insertions/deletions by shifting spans and exposes helpers to toggle/apply
/// formatting on the current selection.
class URichTextController extends TextEditingController {
  URichTextController({super.text, List<UStyleSpan>? spans}) : spans = spans ?? <UStyleSpan>[];

  final List<UStyleSpan> spans;

  /// Formatting queued for the next typed character while the selection is
  /// collapsed (so pressing bold then typing produces bold text).
  final Map<UInlineAttr, Object?> pending = <UInlineAttr, Object?>{};

  /// Optional hook so subclasses can react to text edits before spans shift.
  void onBeforeTextChange(String oldText, String newText) {}

  // Keep spans aligned with the text whenever the value changes.
  @override
  set value(TextEditingValue newValue) {
    final String oldText = value.text;
    final String newText = newValue.text;
    if (oldText != newText) {
      onBeforeTextChange(oldText, newText);
      _shiftSpans(oldText, newText);
    }
    super.value = newValue;
  }

  // ---- span maintenance on text edits -------------------------------------

  void _shiftSpans(String oldText, String newText) {
    final int oldLen = oldText.length;
    final int newLen = newText.length;
    final int minLen = oldLen < newLen ? oldLen : newLen;

    int prefix = 0;
    while (prefix < minLen && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) prefix++;

    int suffix = 0;
    while (suffix < minLen - prefix && oldText.codeUnitAt(oldLen - 1 - suffix) == newText.codeUnitAt(newLen - 1 - suffix)) suffix++;

    final int removedEnd = oldLen - suffix; // region [prefix, removedEnd) removed
    final int insertedEnd = newLen - suffix; // region [prefix, insertedEnd) added
    final int delta = insertedEnd - removedEnd;

    final List<UStyleSpan> next = <UStyleSpan>[];
    for (final UStyleSpan sp in spans) {
      final int a = mapOffsetStart(sp.start, prefix, removedEnd, delta);
      final int b = mapOffsetEnd(sp.end, prefix, removedEnd, delta);
      if (b > a) next.add(UStyleSpan(start: a, end: b, attr: sp.attr, value: sp.value));
    }
    spans
      ..clear()
      ..addAll(next);

    // Extend spans that ended exactly where new text was typed, so continuing to
    // type inside a styled run keeps the style.
    if (delta > 0 && removedEnd == prefix) {
      for (final UStyleSpan sp in spans) {
        if (sp.end == prefix && sp.start < prefix) sp.end = prefix + delta;
      }
      if (pending.isNotEmpty) {
        pending.forEach((UInlineAttr attr, Object? v) => spans.add(UStyleSpan(start: prefix, end: prefix + delta, attr: attr, value: v)));
        pending.clear();
      }
      normalize();
    }
  }

  /// Remaps a range start across an edit that replaced
  /// `[prefix, removedEnd)` with a region of length `removedEnd - prefix + delta`.
  static int mapOffsetStart(int x, int prefix, int removedEnd, int delta) {
    if (x <= prefix) return x;
    if (x >= removedEnd) return x + delta;
    return prefix;
  }

  /// Remaps a range end across the same edit as [mapOffsetStart].
  static int mapOffsetEnd(int x, int prefix, int removedEnd, int delta) {
    if (x < prefix) return x;
    if (x >= removedEnd) return x + delta;
    return prefix;
  }

  // ---- querying -----------------------------------------------------------

  /// The active boolean attributes covering the whole current selection.
  Set<UInlineAttr> activeAttributes() {
    final TextSelection sel = selection;
    if (!sel.isValid) return <UInlineAttr>{};
    final int s = sel.start;
    final int e = sel.end;
    final Set<UInlineAttr> result = <UInlineAttr>{};
    for (final UInlineAttr attr in uBooleanInlineAttrs) {
      if (pending.containsKey(attr)) {
        result.add(attr);
        continue;
      }
      if (s == e) {
        if (_attrCoversPoint(attr, s)) result.add(attr);
      } else if (_attrCoversRange(attr, s, e)) {
        result.add(attr);
      }
    }
    return result;
  }

  /// The value of a value-attribute at the current selection, or null when the
  /// selection is not uniformly covered by it.
  Object? activeValue(UInlineAttr attr) {
    final TextSelection sel = selection;
    if (!sel.isValid) return null;
    if (pending.containsKey(attr)) return pending[attr];
    final int probe = sel.isCollapsed ? sel.start - 1 : sel.start;
    if (probe < 0) return null;
    for (final UStyleSpan sp in spans) {
      if (sp.attr == attr && probe >= sp.start && probe < sp.end) return sp.value;
    }
    return null;
  }

  /// The href active at the current selection, or null.
  String? activeLink() => activeValue(UInlineAttr.link) as String?;

  bool _attrCoversPoint(UInlineAttr attr, int caret) {
    final int i = caret - 1;
    if (i < 0) return false;
    return spans.any((UStyleSpan sp) => sp.attr == attr && i >= sp.start && i < sp.end);
  }

  bool _attrCoversRange(UInlineAttr attr, int s, int e) {
    for (int i = s; i < e; i++) {
      if (!spans.any((UStyleSpan sp) => sp.attr == attr && i >= sp.start && i < sp.end)) return false;
    }
    return true;
  }

  // ---- mutation -----------------------------------------------------------

  /// Toggle a boolean attribute over the current selection. With a collapsed
  /// selection the attribute is queued for the next typed characters.
  void toggleAttribute(UInlineAttr attr) {
    final TextSelection sel = selection;
    if (!sel.isValid) return;
    if (sel.isCollapsed) {
      if (pending.containsKey(attr))
        pending.remove(attr);
      else
        pending[attr] = null;
      notifyListeners();
      return;
    }
    if (_attrCoversRange(attr, sel.start, sel.end))
      removeAttr(attr, sel.start, sel.end);
    else
      spans.add(UStyleSpan(start: sel.start, end: sel.end, attr: attr));
    normalize();
    notifyListeners();
  }

  /// Apply (or clear when [value] is null) a value-attribute over the selection.
  void applyValue(UInlineAttr attr, Object? value) {
    final TextSelection sel = selection;
    if (!sel.isValid) return;
    if (sel.isCollapsed) {
      if (value == null)
        pending.remove(attr);
      else
        pending[attr] = value;
      notifyListeners();
      return;
    }
    removeAttr(attr, sel.start, sel.end);
    if (value != null) spans.add(UStyleSpan(start: sel.start, end: sel.end, attr: attr, value: value));
    normalize();
    notifyListeners();
  }

  /// Remove every inline attribute over the current selection.
  void clearFormatting() {
    final TextSelection sel = selection;
    pending.clear();
    if (!sel.isValid || sel.isCollapsed) {
      notifyListeners();
      return;
    }
    for (final UInlineAttr attr in UInlineAttr.values) removeAttr(attr, sel.start, sel.end);
    normalize();
    notifyListeners();
  }

  /// Replace the whole styled content in one shot.
  void setContent(String newText, List<UStyleSpan> newSpans, {int? caret}) {
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: (caret ?? newText.length).clamp(0, newText.length)),
    );
    spans
      ..clear()
      ..addAll(newSpans.map((UStyleSpan sp) => sp.copy()));
    normalize();
    notifyListeners();
  }

  /// Subtract the range [s, e) from every span of [attr], splitting as needed.
  void removeAttr(UInlineAttr attr, int s, int e) {
    final List<UStyleSpan> result = <UStyleSpan>[];
    for (final UStyleSpan sp in spans) {
      if (sp.attr != attr || sp.end <= s || sp.start >= e) {
        result.add(sp);
        continue;
      }
      if (sp.start < s) result.add(UStyleSpan(start: sp.start, end: s, attr: attr, value: sp.value));
      if (sp.end > e) result.add(UStyleSpan(start: e, end: sp.end, attr: attr, value: sp.value));
    }
    spans
      ..clear()
      ..addAll(result);
  }

  /// Merge touching/overlapping spans that share attr + value.
  void normalize() {
    spans.removeWhere((UStyleSpan sp) => sp.end <= sp.start);
    spans.sort((UStyleSpan a, UStyleSpan b) => a.attr.index != b.attr.index ? a.attr.index - b.attr.index : a.start - b.start);
    final List<UStyleSpan> merged = <UStyleSpan>[];
    for (final UStyleSpan sp in spans) {
      if (merged.isNotEmpty) {
        final UStyleSpan last = merged.last;
        if (last.attr == sp.attr && last.value == sp.value && sp.start <= last.end) {
          if (sp.end > last.end) last.end = sp.end;
          continue;
        }
      }
      merged.add(sp.copy());
    }
    spans
      ..clear()
      ..addAll(merged);
  }

  /// A deep copy of the current spans, for undo snapshots.
  List<UStyleSpan> snapshotSpans() => <UStyleSpan>[for (final UStyleSpan sp in spans) sp.copy()];

  // ---- rendering ----------------------------------------------------------

  @override
  TextSpan buildTextSpan({required BuildContext context, required bool withComposing, TextStyle? style}) {
    final String t = text;
    final TextStyle base = style ?? const TextStyle();
    if (t.isEmpty || spans.isEmpty) return TextSpan(style: base, text: t);

    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<InlineSpan> children = <InlineSpan>[];
    int runStart = 0;
    TextStyle current = styleAt(0, base, cs);
    for (int i = 1; i <= t.length; i++) {
      final TextStyle st = i < t.length ? styleAt(i, base, cs) : current;
      if (i == t.length || st != current) {
        children.add(TextSpan(text: t.substring(runStart, i), style: current));
        runStart = i;
        current = st;
      }
    }
    return TextSpan(style: base, children: children);
  }

  /// The resolved [TextStyle] for the character at index [i].
  TextStyle styleAt(int i, TextStyle base, ColorScheme cs) {
    final Map<UInlineAttr, Object?> active = <UInlineAttr, Object?>{};
    for (final UStyleSpan sp in spans) {
      if (i >= sp.start && i < sp.end) active[sp.attr] = sp.value;
    }
    return resolveStyle(active, base, cs);
  }

  /// Turns a map of active attributes into a [TextStyle] on top of [base].
  static TextStyle resolveStyle(Map<UInlineAttr, Object?> active, TextStyle base, ColorScheme cs) {
    final bool link = active.containsKey(UInlineAttr.link);
    final bool inlineCode = active.containsKey(UInlineAttr.code);
    final List<TextDecoration> decos = <TextDecoration>[
      if (active.containsKey(UInlineAttr.underline) || link) TextDecoration.underline,
      if (active.containsKey(UInlineAttr.strikethrough)) TextDecoration.lineThrough,
    ];
    final int? color = active[UInlineAttr.color] as int?;
    final int? highlight = active[UInlineAttr.highlight] as int?;
    final double? size = active[UInlineAttr.fontSize] as double?;
    final bool sup = active.containsKey(UInlineAttr.superscript);
    final bool sub = active.containsKey(UInlineAttr.subscript);
    // Sub/superscript are approximated with a smaller font plus a baseline shift.
    final double? resolvedSize = sup || sub ? (size ?? base.fontSize ?? 16) * 0.72 : size;
    return base.copyWith(
      fontWeight: active.containsKey(UInlineAttr.bold) ? FontWeight.bold : null,
      fontStyle: active.containsKey(UInlineAttr.italic) ? FontStyle.italic : null,
      decoration: decos.isEmpty ? null : TextDecoration.combine(decos),
      decorationColor: link
          ? cs.primary
          : color != null
          ? Color(color)
          : null,
      color: link
          ? cs.primary
          : color != null
          ? Color(color)
          : (inlineCode ? cs.error : null),
      backgroundColor: highlight != null ? Color(highlight) : (inlineCode ? cs.surfaceContainerHighest : null),
      fontSize: resolvedSize,
      fontFamily: active.containsKey(UInlineAttr.fontFamily) ? active[UInlineAttr.fontFamily] as String? : (inlineCode ? "monospace" : null),
      height: sup || sub ? 1.0 : null,
      textBaseline: TextBaseline.alphabetic,
    );
  }
}

/// The cells of a [UBlockType.table] block. Cells hold plain text.
class UTableData {
  UTableData({required this.rows, this.hasHeader = true});

  /// Creates an empty table of [rows] x [columns].
  factory UTableData.empty({int rows = 3, int columns = 3}) => UTableData(
    rows: <List<String>>[
      for (int r = 0; r < rows; r++) <String>[for (int c = 0; c < columns; c++) ""],
    ],
  );

  final List<List<String>> rows;
  bool hasHeader;

  int get rowCount => rows.length;

  int get columnCount => rows.isEmpty ? 0 : rows.first.length;

  void addRow() => rows.add(<String>[for (int c = 0; c < columnCount; c++) ""]);

  void addColumn() {
    for (final List<String> row in rows) row.add("");
  }

  void removeRow(int index) {
    if (rows.length > 1 && index >= 0 && index < rows.length) rows.removeAt(index);
  }

  void removeColumn(int index) {
    if (columnCount <= 1) return;
    for (final List<String> row in rows) {
      if (index >= 0 && index < row.length) row.removeAt(index);
    }
  }

  UTableData copy() => UTableData(rows: <List<String>>[for (final List<String> r in rows) List<String>.from(r)], hasHeader: hasHeader);
}

/// One block in the editor document.
class UEditorBlock {
  UEditorBlock({
    required this.type,
    this.controller,
    this.focusNode,
    this.imageUrl,
    this.imageAlt,
    this.imageWidth,
    this.align = TextAlign.start,
    this.indent = 0,
    this.checked = false,
    this.language,
    this.table,
  }) : id = "b${DateTime.now().microsecondsSinceEpoch}_${_seq++}";

  static int _seq = 0;

  final String id;
  UBlockType type;
  URichTextController? controller;
  FocusNode? focusNode;
  String? imageUrl;
  String? imageAlt;
  double? imageWidth;
  TextAlign align;
  int indent;
  bool checked;
  String? language;
  UTableData? table;

  bool get isText => type != UBlockType.image && type != UBlockType.divider && type != UBlockType.table;

  bool get isList => type == UBlockType.bulleted || type == UBlockType.numbered || type == UBlockType.checklist;

  /// Convenience factory for a text block seeded with [text] and [spans].
  factory UEditorBlock.text(
    UBlockType type, {
    String text = "",
    List<UStyleSpan>? spans,
    TextAlign align = TextAlign.start,
    int indent = 0,
    bool checked = false,
    String? language,
  }) => UEditorBlock(
    type: type,
    controller: URichTextController(text: text, spans: spans),
    focusNode: FocusNode(),
    align: align,
    indent: indent,
    checked: checked,
    language: language,
  );

  void dispose() {
    controller?.dispose();
    focusNode?.dispose();
  }
}

// =============================================================================
//  HTML  (serialize / parse)
// =============================================================================

/// Serializes editor blocks to clean semantic HTML and parses HTML back into
/// blocks. Pure Dart, no external dependencies.
abstract class UHtmlDocument {
  /// Width of a single indent level in CSS pixels.
  static const double indentStep = 24;

  // ---- serialize (blocks -> html) -----------------------------------------

  static String serialize(List<UEditorBlock> blocks) {
    final StringBuffer sb = StringBuffer();
    int i = 0;
    while (i < blocks.length) {
      final UEditorBlock b = blocks[i];
      if (b.isList) {
        final UBlockType listType = b.type;
        final String tag = listType == UBlockType.numbered ? "ol" : "ul";
        final String cls = listType == UBlockType.checklist ? ' class="checklist"' : "";
        sb.write("<$tag$cls>");
        while (i < blocks.length && blocks[i].type == listType) {
          sb.write(_listItem(blocks[i]));
          i++;
        }
        sb.write("</$tag>");
        continue;
      }
      sb.write(_serializeBlock(b));
      i++;
    }
    return sb.toString();
  }

  static String _listItem(UEditorBlock b) {
    final String checked = b.type == UBlockType.checklist ? ' data-checked="${b.checked}"' : "";
    return "<li$checked${_styleAttr(b)}>${inlineHtml(b.controller!)}</li>";
  }

  static String _serializeBlock(UEditorBlock b) {
    final String style = _styleAttr(b);
    switch (b.type) {
      case UBlockType.paragraph:
        return "<p$style>${inlineHtml(b.controller!)}</p>";
      case UBlockType.h1:
        return "<h1$style>${inlineHtml(b.controller!)}</h1>";
      case UBlockType.h2:
        return "<h2$style>${inlineHtml(b.controller!)}</h2>";
      case UBlockType.h3:
        return "<h3$style>${inlineHtml(b.controller!)}</h3>";
      case UBlockType.h4:
        return "<h4$style>${inlineHtml(b.controller!)}</h4>";
      case UBlockType.h5:
        return "<h5$style>${inlineHtml(b.controller!)}</h5>";
      case UBlockType.h6:
        return "<h6$style>${inlineHtml(b.controller!)}</h6>";
      case UBlockType.quote:
        return "<blockquote$style>${inlineHtml(b.controller!)}</blockquote>";
      case UBlockType.code:
        final String lang = (b.language ?? "").trim().isEmpty ? "" : ' class="language-${escapeAttr(b.language!.trim())}"';
        return "<pre><code$lang>${escapeHtml(b.controller!.text)}</code></pre>";
      case UBlockType.divider:
        return "<hr>";
      case UBlockType.image:
        final String alt = escapeAttr(b.imageAlt ?? "");
        final String width = b.imageWidth == null ? "" : ' width="${b.imageWidth!.round()}"';
        return '<figure${_alignStyle(b.align)}><img src="${escapeAttr(b.imageUrl ?? "")}" alt="$alt"$width></figure>';
      case UBlockType.table:
        return _serializeTable(b.table ?? UTableData.empty());
      case UBlockType.bulleted:
      case UBlockType.numbered:
      case UBlockType.checklist:
        return _listItem(b);
    }
  }

  static String _serializeTable(UTableData table) {
    final StringBuffer sb = StringBuffer("<table>");
    for (int r = 0; r < table.rows.length; r++) {
      final bool header = table.hasHeader && r == 0;
      if (header) sb.write("<thead>");
      if (r == (table.hasHeader ? 1 : 0)) sb.write("<tbody>");
      sb.write("<tr>");
      for (final String cell in table.rows[r]) sb.write(header ? "<th>${escapeHtml(cell)}</th>" : "<td>${escapeHtml(cell)}</td>");
      sb.write("</tr>");
      if (header) sb.write("</thead>");
    }
    if (table.rows.length > (table.hasHeader ? 1 : 0)) sb.write("</tbody>");
    sb.write("</table>");
    return sb.toString();
  }

  // Combines alignment and indentation into a single style attribute.
  static String _styleAttr(UEditorBlock b) {
    final List<String> decls = <String>[
      if (_alignValue(b.align) != null) "text-align:${_alignValue(b.align)}",
      if (b.indent > 0) "margin-inline-start:${(b.indent * indentStep).round()}px",
    ];
    return decls.isEmpty ? "" : ' style="${decls.join(";")}"';
  }

  static String _alignStyle(TextAlign align) {
    final String? value = _alignValue(align);
    return value == null ? "" : ' style="text-align:$value"';
  }

  static String? _alignValue(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return "center";
      case TextAlign.right:
      case TextAlign.end:
        return "right";
      case TextAlign.left:
        return "left";
      case TextAlign.justify:
        return "justify";
      // start follows the ambient text direction, so it emits no CSS.
      case TextAlign.start:
        return null;
    }
  }

  // Priority order (outer -> inner) for nesting inline tags.
  static const List<UInlineAttr> _priority = <UInlineAttr>[
    UInlineAttr.link,
    UInlineAttr.fontFamily,
    UInlineAttr.highlight,
    UInlineAttr.color,
    UInlineAttr.fontSize,
    UInlineAttr.bold,
    UInlineAttr.italic,
    UInlineAttr.underline,
    UInlineAttr.strikethrough,
    UInlineAttr.code,
    UInlineAttr.superscript,
    UInlineAttr.subscript,
  ];

  /// Serializes one styled text run to inline HTML.
  static String inlineHtml(URichTextController c) => inlineHtmlOf(c.text, c.spans);

  /// Serializes [text] with [spans] to inline HTML.
  static String inlineHtmlOf(String text, List<UStyleSpan> spans) {
    if (text.isEmpty) return "";
    final StringBuffer out = StringBuffer();
    final List<_Tag> stack = <_Tag>[];

    for (int i = 0; i < text.length; i++) {
      final List<_Tag> active = _tagsAt(spans, i);
      int common = 0;
      while (common < stack.length && common < active.length && stack[common] == active[common]) common++;
      for (int k = stack.length - 1; k >= common; k--) out.write(stack[k].close());
      stack.removeRange(common, stack.length);
      for (int k = common; k < active.length; k++) {
        out.write(active[k].open());
        stack.add(active[k]);
      }
      final String ch = text[i];
      out.write(ch == "\n" ? "<br>" : escapeHtml(ch));
    }
    for (int k = stack.length - 1; k >= 0; k--) out.write(stack[k].close());
    return out.toString();
  }

  static List<_Tag> _tagsAt(List<UStyleSpan> spans, int i) {
    final Map<UInlineAttr, Object?> active = <UInlineAttr, Object?>{};
    for (final UStyleSpan sp in spans) {
      if (i >= sp.start && i < sp.end) active[sp.attr] = sp.value;
    }
    final List<_Tag> tags = <_Tag>[];
    for (final UInlineAttr attr in _priority) {
      if (active.containsKey(attr)) tags.add(_Tag(attr, active[attr]));
    }
    return tags;
  }

  static String escapeHtml(String s) => s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

  static String escapeAttr(String s) => escapeHtml(s).replaceAll('"', "&quot;");

  // ---- parse (html -> blocks) ---------------------------------------------

  static List<UEditorBlock> parse(String? html) {
    final String input = (html ?? "").trim();
    if (input.isEmpty) return <UEditorBlock>[UEditorBlock.text(UBlockType.paragraph)];

    final List<_Node> nodes = _Parser(input).parse();
    final List<UEditorBlock> blocks = <UEditorBlock>[];
    _walkTopLevel(nodes, blocks);

    if (blocks.isEmpty) blocks.add(UEditorBlock.text(UBlockType.paragraph));
    return blocks;
  }

  /// Strips all tags, returning the readable text of [html].
  static String toPlainText(String? html) {
    final List<UEditorBlock> blocks = parse(html);
    final String text = blocks
        .map((UEditorBlock b) => b.isText ? b.controller!.text : (b.type == UBlockType.table ? (b.table?.rows.map((List<String> r) => r.join(" ")).join("\n") ?? "") : ""))
        .where((String s) => s.isNotEmpty)
        .join("\n");
    for (final UEditorBlock b in blocks) b.dispose();
    return text;
  }

  /// Number of whitespace-separated words in [html].
  static int wordCount(String? html) => toPlainText(html).split(RegExp(r"\s+")).where((String w) => w.trim().isNotEmpty).length;

  /// Number of characters (excluding markup) in [html].
  static int characterCount(String? html) => toPlainText(html).replaceAll("\n", "").length;

  /// Rough reading time in minutes at [wordsPerMinute].
  static int readingMinutes(String? html, {int wordsPerMinute = 200}) {
    final int words = wordCount(html);
    return words == 0 ? 0 : (words / wordsPerMinute).ceil();
  }

  static void _walkTopLevel(List<_Node> nodes, List<UEditorBlock> blocks) {
    for (final _Node node in nodes) {
      if (node.isText) {
        final String txt = node.text!.trim();
        if (txt.isNotEmpty) blocks.add(UEditorBlock.text(UBlockType.paragraph, text: node.text!));
        continue;
      }
      switch (node.tag) {
        case "p":
        case "div":
        case "section":
        case "article":
          _addInlineBlock(node, UBlockType.paragraph, blocks);
        case "h1":
          _addInlineBlock(node, UBlockType.h1, blocks);
        case "h2":
          _addInlineBlock(node, UBlockType.h2, blocks);
        case "h3":
          _addInlineBlock(node, UBlockType.h3, blocks);
        case "h4":
          _addInlineBlock(node, UBlockType.h4, blocks);
        case "h5":
          _addInlineBlock(node, UBlockType.h5, blocks);
        case "h6":
          _addInlineBlock(node, UBlockType.h6, blocks);
        case "blockquote":
          _addInlineBlock(node, UBlockType.quote, blocks);
        case "pre":
          blocks.add(UEditorBlock.text(UBlockType.code, text: _plainText(node), language: _languageOf(node)));
        case "hr":
          blocks.add(UEditorBlock(type: UBlockType.divider));
        case "ul":
          _addList(node, node.attrs["class"]?.contains("checklist") ?? false ? UBlockType.checklist : UBlockType.bulleted, blocks);
        case "ol":
          _addList(node, UBlockType.numbered, blocks);
        case "table":
          blocks.add(UEditorBlock(type: UBlockType.table, table: _parseTable(node)));
        case "figure":
          final _Node? img = _findFirst(node, "img");
          if (img != null) blocks.add(_imageBlock(img, _alignOf(node)));
          _walkTopLevel(node.children.where((_Node n) => !n.isText && n.tag != "img" && n.tag != "figcaption").toList(), blocks);
        case "img":
          blocks.add(_imageBlock(node, TextAlign.left));
        case "br":
          break;
        default:
          _walkTopLevel(node.children, blocks);
      }
    }
  }

  static String? _languageOf(_Node pre) {
    final _Node? code = _findFirst(pre, "code");
    final String cls = code?.attrs["class"] ?? pre.attrs["class"] ?? "";
    final RegExpMatch? m = RegExp(r"language-([\w+#-]+)").firstMatch(cls);
    return m?.group(1);
  }

  static UTableData _parseTable(_Node node) {
    final List<List<String>> rows = <List<String>>[];
    bool hasHeader = false;
    void walkRows(_Node n) {
      if (n.isText) return;
      if (n.tag == "tr") {
        final List<String> cells = <String>[];
        for (final _Node cell in n.children.where((_Node c) => !c.isText && (c.tag == "td" || c.tag == "th"))) {
          if (cell.tag == "th" && rows.isEmpty) hasHeader = true;
          cells.add(_plainText(cell).trim());
        }
        if (cells.isNotEmpty) rows.add(cells);
        return;
      }
      n.children.forEach(walkRows);
    }

    node.children.forEach(walkRows);
    if (rows.isEmpty) return UTableData.empty();
    // Pad short rows so the grid stays rectangular.
    final int width = rows.map((List<String> r) => r.length).reduce((int a, int b) => a > b ? a : b);
    for (final List<String> r in rows) {
      while (r.length < width) r.add("");
    }
    return UTableData(rows: rows, hasHeader: hasHeader);
  }

  static void _addInlineBlock(_Node node, UBlockType type, List<UEditorBlock> blocks) {
    final _Inline inline = _collectInline(node);
    blocks.add(UEditorBlock.text(type, text: inline.text, spans: inline.spans, align: _alignOf(node), indent: _indentOf(node)));
  }

  static void _addList(_Node node, UBlockType itemType, List<UEditorBlock> blocks) {
    for (final _Node li in node.children.where((_Node n) => !n.isText && n.tag == "li")) {
      final _Inline inline = _collectInline(li);
      final bool checked = (li.attrs["data-checked"] ?? "").toLowerCase() == "true";
      blocks.add(UEditorBlock.text(itemType, text: inline.text, spans: inline.spans, align: _alignOf(li), indent: _indentOf(li), checked: checked));
      // Nested lists become deeper-indented items of the same kind.
      for (final _Node nested in li.children.where((_Node n) => !n.isText && (n.tag == "ul" || n.tag == "ol"))) {
        final int before = blocks.length;
        _addList(nested, nested.tag == "ol" ? UBlockType.numbered : itemType, blocks);
        for (int i = before; i < blocks.length; i++) blocks[i].indent += 1;
      }
    }
  }

  static UEditorBlock _imageBlock(_Node img, TextAlign align) => UEditorBlock(
    type: UBlockType.image,
    imageUrl: img.attrs["src"],
    imageAlt: img.attrs["alt"],
    imageWidth: double.tryParse((img.attrs["width"] ?? "").replaceAll("px", "")),
    align: align,
  );

  static TextAlign _alignOf(_Node node) {
    final String? style = node.attrs["style"];
    if (style == null) return TextAlign.start;
    final RegExpMatch? m = RegExp(r"text-align\s*:\s*([a-z]+)").firstMatch(style.toLowerCase());
    switch (m?.group(1)) {
      case "center":
        return TextAlign.center;
      case "right":
        return TextAlign.right;
      case "left":
        return TextAlign.left;
      case "justify":
        return TextAlign.justify;
      default:
        return TextAlign.start;
    }
  }

  static int _indentOf(_Node node) {
    final String style = (node.attrs["style"] ?? "").toLowerCase();
    final RegExpMatch? m = RegExp(r"(?:margin-inline-start|margin-left|padding-left)\s*:\s*([\d.]+)px").firstMatch(style);
    if (m == null) return 0;
    final double px = double.tryParse(m.group(1)!) ?? 0;
    return (px / indentStep).round().clamp(0, 8);
  }

  static _Node? _findFirst(_Node node, String tag) {
    for (final _Node c in node.children) {
      if (!c.isText && c.tag == tag) return c;
      final _Node? deep = _findFirst(c, tag);
      if (deep != null) return deep;
    }
    return null;
  }

  static String _plainText(_Node node) {
    final StringBuffer sb = StringBuffer();
    void walk(_Node n) {
      if (n.isText) {
        sb.write(n.text);
        return;
      }
      if (n.tag == "br") {
        sb.write("\n");
        return;
      }
      n.children.forEach(walk);
    }

    node.children.forEach(walk);
    return sb.toString();
  }

  static _Inline _collectInline(_Node node) {
    final StringBuffer buffer = StringBuffer();
    final List<UStyleSpan> spans = <UStyleSpan>[];

    void walk(_Node n) {
      if (n.isText) {
        buffer.write(n.text);
        return;
      }
      if (n.tag == "br") {
        buffer.write("\n");
        return;
      }
      // Nested lists are handled by the caller, not inlined into the item text.
      if (n.tag == "ul" || n.tag == "ol") return;
      final int start = buffer.length;
      final List<UStyleSpan> local = <UStyleSpan>[];
      switch (n.tag) {
        case "strong":
        case "b":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.bold));
        case "em":
        case "i":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.italic));
        case "u":
        case "ins":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.underline));
        case "s":
        case "strike":
        case "del":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.strikethrough));
        case "code":
        case "kbd":
        case "samp":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.code));
        case "sup":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.superscript));
        case "sub":
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.subscript));
        case "mark":
          final Map<UInlineAttr, Object?> styles = _parseInlineStyle(n.attrs["style"], null);
          local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.highlight, value: styles[UInlineAttr.highlight] ?? 0xFFFFF59D));
        case "a":
          final String? href = n.attrs["href"];
          if (href != null) local.add(UStyleSpan(start: start, end: start, attr: UInlineAttr.link, value: href));
        case "span":
        case "font":
          final Map<UInlineAttr, Object?> styles = _parseInlineStyle(n.attrs["style"], n.attrs["color"]);
          styles.forEach((UInlineAttr attr, Object? value) => local.add(UStyleSpan(start: start, end: start, attr: attr, value: value)));
      }
      n.children.forEach(walk);
      final int end = buffer.length;
      for (final UStyleSpan sp in local) {
        if (end > start) spans.add(UStyleSpan(start: start, end: end, attr: sp.attr, value: sp.value));
      }
    }

    node.children.forEach(walk);
    return _Inline(buffer.toString(), spans);
  }

  static Map<UInlineAttr, Object?> _parseInlineStyle(String? style, String? colorAttr) {
    final Map<UInlineAttr, Object?> result = <UInlineAttr, Object?>{};
    if (colorAttr != null) {
      final int? c = parseCssColor(colorAttr);
      if (c != null) result[UInlineAttr.color] = c;
    }
    if (style == null) return result;
    for (final String decl in style.split(";")) {
      final int idx = decl.indexOf(":");
      if (idx <= 0) continue;
      final String prop = decl.substring(0, idx).trim().toLowerCase();
      final String value = decl.substring(idx + 1).trim();
      if (prop == "color") {
        final int? c = parseCssColor(value);
        if (c != null) result[UInlineAttr.color] = c;
      } else if (prop == "background-color" || prop == "background") {
        final int? c = parseCssColor(value);
        if (c != null) result[UInlineAttr.highlight] = c;
      } else if (prop == "font-size") {
        final double? size = _parseFontSize(value);
        if (size != null) result[UInlineAttr.fontSize] = size;
      } else if (prop == "font-family") {
        final String family = value.split(",").first.replaceAll('"', "").replaceAll("'", "").trim();
        if (family.isNotEmpty) result[UInlineAttr.fontFamily] = family;
      } else if (prop == "font-weight") {
        if (value == "bold" || (int.tryParse(value) ?? 0) >= 600) result[UInlineAttr.bold] = null;
      } else if (prop == "font-style" && value == "italic") {
        result[UInlineAttr.italic] = null;
      } else if (prop == "vertical-align") {
        if (value == "super") result[UInlineAttr.superscript] = null;
        if (value == "sub") result[UInlineAttr.subscript] = null;
      } else if (prop == "text-decoration" || prop == "text-decoration-line") {
        if (value.contains("underline")) result[UInlineAttr.underline] = null;
        if (value.contains("line-through")) result[UInlineAttr.strikethrough] = null;
      }
    }
    return result;
  }

  /// Parses `#rgb`, `#rrggbb`, `#aarrggbb` and `rgb()/rgba()` into ARGB.
  static int? parseCssColor(String raw) {
    String v = raw.trim().toLowerCase();
    if (v.startsWith("#")) {
      v = v.substring(1);
      if (v.length == 3) v = v.split("").map((String c) => "$c$c").join();
      if (v.length == 6) {
        final int? rgb = int.tryParse(v, radix: 16);
        if (rgb != null) return 0xFF000000 | rgb;
      }
      if (v.length == 8) return int.tryParse(v, radix: 16);
      return null;
    }
    if (v.startsWith("rgb")) {
      final RegExpMatch? m = RegExp(r"(\d+)\D+(\d+)\D+(\d+)").firstMatch(v);
      if (m != null) {
        final int r = int.parse(m.group(1)!);
        final int g = int.parse(m.group(2)!);
        final int b = int.parse(m.group(3)!);
        return 0xFF000000 | (r << 16) | (g << 8) | b;
      }
    }
    return null;
  }

  static double? _parseFontSize(String raw) {
    final RegExpMatch? m = RegExp(r"([\d.]+)\s*px").firstMatch(raw.toLowerCase());
    if (m != null) return double.tryParse(m.group(1)!);
    return double.tryParse(raw);
  }
}

// ---- serialize helpers ------------------------------------------------------

class _Tag {
  _Tag(this.attr, this.value);

  final UInlineAttr attr;
  final Object? value;

  String open() {
    switch (attr) {
      case UInlineAttr.bold:
        return "<strong>";
      case UInlineAttr.italic:
        return "<em>";
      case UInlineAttr.underline:
        return "<u>";
      case UInlineAttr.strikethrough:
        return "<s>";
      case UInlineAttr.code:
        return "<code>";
      case UInlineAttr.superscript:
        return "<sup>";
      case UInlineAttr.subscript:
        return "<sub>";
      case UInlineAttr.link:
        return '<a href="${UHtmlDocument.escapeAttr("$value")}">';
      case UInlineAttr.color:
        return '<span style="color:${_hex(value! as int)}">';
      case UInlineAttr.highlight:
        return '<mark style="background-color:${_hex(value! as int)}">';
      case UInlineAttr.fontSize:
        return '<span style="font-size:${_size(value! as double)}">';
      case UInlineAttr.fontFamily:
        return '<span style="font-family:${UHtmlDocument.escapeAttr("$value")}">';
    }
  }

  String close() {
    switch (attr) {
      case UInlineAttr.bold:
        return "</strong>";
      case UInlineAttr.italic:
        return "</em>";
      case UInlineAttr.underline:
        return "</u>";
      case UInlineAttr.strikethrough:
        return "</s>";
      case UInlineAttr.code:
        return "</code>";
      case UInlineAttr.superscript:
        return "</sup>";
      case UInlineAttr.subscript:
        return "</sub>";
      case UInlineAttr.link:
        return "</a>";
      case UInlineAttr.highlight:
        return "</mark>";
      case UInlineAttr.color:
      case UInlineAttr.fontSize:
      case UInlineAttr.fontFamily:
        return "</span>";
    }
  }

  static String _hex(int argb) => "#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, "0")}";

  static String _size(double px) => px == px.roundToDouble() ? "${px.toInt()}px" : "${px}px";

  @override
  bool operator ==(Object other) => other is _Tag && other.attr == attr && other.value == value;

  @override
  int get hashCode => Object.hash(attr, value);
}

// ---- parse model ------------------------------------------------------------

class _Inline {
  _Inline(this.text, this.spans);

  final String text;
  final List<UStyleSpan> spans;
}

class _Node {
  _Node.element(this.tag) : isText = false, text = null;

  _Node.textNode(this.text) : isText = true, tag = "";

  final bool isText;
  String tag;
  final String? text;
  final Map<String, String> attrs = <String, String>{};
  final List<_Node> children = <_Node>[];
}

/// Minimal, forgiving HTML tokenizer + tree builder for the supported subset.
class _Parser {
  _Parser(this.src);

  final String src;
  int _pos = 0;

  static const Set<String> _void = <String>{"img", "hr", "br", "input", "meta", "link", "source", "col"};

  List<_Node> parse() {
    final _Node root = _Node.element("#root");
    final List<_Node> stack = <_Node>[root];

    while (_pos < src.length) {
      final int lt = src.indexOf("<", _pos);
      if (lt < 0) {
        _appendText(stack.last, src.substring(_pos));
        break;
      }
      if (lt > _pos) _appendText(stack.last, src.substring(_pos, lt));

      final int gt = src.indexOf(">", lt);
      if (gt < 0) {
        _appendText(stack.last, src.substring(lt));
        break;
      }
      String raw = src.substring(lt + 1, gt).trim();
      _pos = gt + 1;

      if (raw.startsWith("!") || raw.startsWith("?")) continue;

      if (raw.startsWith("/")) {
        final String name = raw.substring(1).trim().toLowerCase();
        for (int i = stack.length - 1; i > 0; i--) {
          if (stack[i].tag == name) {
            stack.removeRange(i, stack.length);
            break;
          }
        }
        continue;
      }

      final bool selfClose = raw.endsWith("/");
      if (selfClose) raw = raw.substring(0, raw.length - 1).trim();

      final _Node el = _parseTag(raw);
      // Drop non-content elements entirely, including their inner text.
      if (el.tag == "script" || el.tag == "style") {
        final int end = src.toLowerCase().indexOf("</${el.tag}>", _pos);
        _pos = end < 0 ? src.length : end + el.tag.length + 3;
        continue;
      }
      stack.last.children.add(el);
      if (!selfClose && !_void.contains(el.tag)) stack.add(el);
    }
    return root.children;
  }

  void _appendText(_Node parent, String raw) {
    if (raw.isEmpty) return;
    parent.children.add(_Node.textNode(_decode(raw)));
  }

  _Node _parseTag(String raw) {
    int i = 0;
    while (i < raw.length && !_isSpace(raw[i])) i++;
    final _Node el = _Node.element(raw.substring(0, i).toLowerCase());
    final RegExp attr = RegExp("""([a-zA-Z_:-][a-zA-Z0-9_:.-]*)\\s*(?:=\\s*("[^"]*"|'[^']*'|[^\\s>]+))?""");
    for (final RegExpMatch m in attr.allMatches(raw.substring(i))) {
      final String key = m.group(1)!.toLowerCase();
      String? value = m.group(2);
      if (value != null && value.length >= 2 && (value.startsWith('"') || value.startsWith("'"))) value = value.substring(1, value.length - 1);
      el.attrs[key] = _decode(value ?? "");
    }
    return el;
  }

  bool _isSpace(String c) => c == " " || c == "\t" || c == "\n" || c == "\r";

  static String _decode(String s) {
    if (!s.contains("&")) return s;
    return s
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&")
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", '"')
        .replaceAll("&#39;", "'")
        .replaceAll("&#x27;", "'")
        .replaceAllMapped(RegExp(r"&#(\d+);"), (Match m) => String.fromCharCode(int.parse(m.group(1)!)))
        .replaceAllMapped(RegExp("&#x([0-9a-fA-F]+);"), (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)));
  }
}

// =============================================================================
//  STYLES
// =============================================================================

/// Shared visual styling for editor blocks (used by the editors and [UHtmlView]).
abstract class UEditorStyles {
  /// Font families offered by the editors' font picker.
  static const List<String> fontFamilies = <String>["Default", "serif", "sans-serif", "monospace", "cursive"];

  /// Font sizes offered by the editors' size picker.
  static const List<double> fontSizes = <double>[10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48, 64];

  /// A small palette used for quick text/highlight colour picking.
  static const List<int> palette = <int>[
    0xFF000000,
    0xFF616161,
    0xFF9E9E9E,
    0xFFD32F2F,
    0xFFE64A19,
    0xFFF9A825,
    0xFF388E3C,
    0xFF0288D1,
    0xFF1976D2,
    0xFF7B1FA2,
    0xFFFFF59D,
    0xFFA5D6A7,
    0xFF90CAF9,
    0xFFF48FB1,
    0xFFFFFFFF,
  ];

  static TextStyle baseStyle(BuildContext context, UBlockType type) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    switch (type) {
      case UBlockType.h1:
        return (t.headlineMedium ?? const TextStyle(fontSize: 30)).copyWith(fontWeight: FontWeight.bold);
      case UBlockType.h2:
        return (t.headlineSmall ?? const TextStyle(fontSize: 24)).copyWith(fontWeight: FontWeight.bold);
      case UBlockType.h3:
        return (t.titleLarge ?? const TextStyle(fontSize: 20)).copyWith(fontWeight: FontWeight.bold);
      case UBlockType.h4:
        return (t.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(fontWeight: FontWeight.bold);
      case UBlockType.h5:
        return (t.titleSmall ?? const TextStyle(fontSize: 16)).copyWith(fontWeight: FontWeight.bold);
      case UBlockType.h6:
        return (t.bodyLarge ?? const TextStyle(fontSize: 15)).copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant);
      case UBlockType.quote:
        return (t.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant);
      case UBlockType.code:
        return (t.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(fontFamily: "monospace", color: cs.onSurface);
      case UBlockType.paragraph:
      case UBlockType.bulleted:
      case UBlockType.numbered:
      case UBlockType.checklist:
      case UBlockType.image:
      case UBlockType.divider:
      case UBlockType.table:
        return t.bodyLarge ?? const TextStyle(fontSize: 16);
    }
  }

  /// Vertical breathing room above/below a block of [type].
  static EdgeInsets spacing(UBlockType type) {
    switch (type) {
      case UBlockType.h1:
      case UBlockType.h2:
        return const EdgeInsets.only(top: 16, bottom: 6);
      case UBlockType.h3:
      case UBlockType.h4:
      case UBlockType.h5:
      case UBlockType.h6:
        return const EdgeInsets.only(top: 12, bottom: 4);
      case UBlockType.divider:
      case UBlockType.image:
      case UBlockType.table:
        return const EdgeInsets.symmetric(vertical: 10);
      case UBlockType.paragraph:
      case UBlockType.quote:
      case UBlockType.code:
      case UBlockType.bulleted:
      case UBlockType.numbered:
      case UBlockType.checklist:
        return const EdgeInsets.symmetric(vertical: 4);
    }
  }

  /// Wrap a block's content with type-specific chrome (quote bar, code panel).
  static Widget decorate(BuildContext context, UBlockType type, Widget child) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    switch (type) {
      case UBlockType.quote:
        return Container(
          padding: const EdgeInsetsDirectional.only(start: 12, top: 4, bottom: 4),
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(width: 4, color: cs.primary)),
          ),
          child: child,
        );
      case UBlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: child,
        );
      default:
        return child;
    }
  }

  /// Localized label for a block type.
  static String label(UBlockType t) {
    switch (t) {
      case UBlockType.paragraph:
        return U.s.normalText;
      case UBlockType.h1:
        return U.s.heading1;
      case UBlockType.h2:
        return U.s.heading2;
      case UBlockType.h3:
        return U.s.heading3;
      case UBlockType.h4:
        return U.s.heading4;
      case UBlockType.h5:
        return U.s.heading5;
      case UBlockType.h6:
        return U.s.heading6;
      case UBlockType.quote:
        return U.s.quote;
      case UBlockType.bulleted:
        return U.s.bulletedList;
      case UBlockType.numbered:
        return U.s.numberedList;
      case UBlockType.checklist:
        return U.s.checklist;
      case UBlockType.code:
        return U.s.codeBlock;
      case UBlockType.table:
        return U.s.table;
      case UBlockType.image:
        return U.s.insertImage;
      case UBlockType.divider:
        return U.s.divider;
    }
  }
}

// =============================================================================
//  TOOLBAR WIDGETS + DIALOGS
// =============================================================================

/// Toolbar widgets and dialogs shared by [URichTextEditor] and
/// Toolbar widgets and dialogs used by [URichTextEditor]. Nothing here holds
/// editor state — every helper takes what it needs and returns a plain result.

/// A single square toolbar button with an active/selected state.
class UEditorToolButton extends StatelessWidget {
  const UEditorToolButton({required this.icon, required this.tooltip, super.key, this.active = false, this.onTap, this.size = 20});

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      isSelected: active,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: active ? cs.primary.withValues(alpha: 0.16) : null,
        foregroundColor: active ? cs.primary : cs.onSurface,
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// A thin vertical rule between toolbar groups.
class UEditorToolSeparator extends StatelessWidget {
  const UEditorToolSeparator({super.key});

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 6), color: Theme.of(context).dividerColor);
}

/// A compact bordered dropdown used for the block-type and font pickers.
class UEditorDropdown<T> extends StatelessWidget {
  const UEditorDropdown({required this.label, required this.items, required this.onSelected, super.key, this.tooltip, this.width});

  final String label;
  final List<UEditorMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final String? tooltip;
  final double? width;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip ?? label,
    onSelected: onSelected,
    itemBuilder: (BuildContext context) => <PopupMenuEntry<T>>[
      for (final UEditorMenuEntry<T> e in items)
        PopupMenuItem<T>(
          value: e.value,
          child: Text(e.label, style: e.style),
        ),
    ],
    child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: UTextBodyMedium(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    ),
  );
}

/// One entry of a [UEditorDropdown].
class UEditorMenuEntry<T> {
  UEditorMenuEntry({required this.value, required this.label, this.style});

  final T value;
  final String label;
  final TextStyle? style;
}

/// The result of the find & replace dialog.
class UFindReplaceRequest {
  UFindReplaceRequest({required this.find, required this.replace, this.matchCase = false, this.replaceAll = true});

  final String find;
  final String replace;
  final bool matchCase;
  final bool replaceAll;
}

/// Dialogs used by both editors.
abstract class UEditorDialogs {
  /// A quick swatch grid plus a full colour picker. Returns the chosen ARGB
  /// value, or `0` when the user picks "none" (i.e. clear the colour).
  static Future<int?> pickColor({required BuildContext context, int? current, bool allowNone = true, String? title}) async {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return UNavigator.dialog<int>(
      AlertDialog(
        title: Text(title ?? U.s.selectAColor),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final int c in UEditorStyles.palette)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: current == c ? cs.primary : cs.outlineVariant, width: current == c ? 3 : 1),
                      ),
                    ).onTap(() => UNavigator.back(c)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  TextButton.icon(
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    label: Text(U.s.more),
                    onPressed: () async {
                      final Color? picked = await UNavigator.colorPicker(defaultColor: current != null ? Color(current) : cs.onSurface);
                      if (picked != null) UNavigator.back(picked.toARGB32());
                    },
                  ),
                  if (allowNone) TextButton(onPressed: () => UNavigator.back(0), child: Text(U.s.none)),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel))],
      ),
    );
  }

  /// Prompts for a link href. Returns an empty string to remove the link.
  static Future<String?> editLink({String? existing}) => UNavigator.inputDialog(title: U.s.insertLink, hint: U.s.url, defaultValue: existing ?? "https://");

  /// Asks for a row/column count and returns a fresh empty table.
  static Future<UTableData?> insertTable() {
    int rows = 3;
    int columns = 3;
    bool header = true;
    return UNavigator.dialog<UTableData>(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setInner) => AlertDialog(
          title: Text(U.s.insertTable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _counter(context, U.s.rows, rows, (int v) => setInner(() => rows = v.clamp(1, 20))),
              _counter(context, U.s.columns, columns, (int v) => setInner(() => columns = v.clamp(1, 10))),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: header,
                title: UTextBodyMedium(U.s.headerRow),
                onChanged: (bool v) => setInner(() => header = v),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
            TextButton(
              onPressed: () => UNavigator.back(UTableData.empty(rows: rows, columns: columns)..hasHeader = header),
              child: Text(U.s.insert),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _counter(BuildContext context, String label, int value, ValueChanged<int> onChanged) => Row(
    children: <Widget>[
      UTextBodyMedium(label).expanded(),
      IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => onChanged(value - 1)),
      SizedBox(width: 28, child: Center(child: UTextBodyMedium("$value"))),
      IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => onChanged(value + 1)),
    ],
  );

  /// Shows the raw HTML and lets the user edit it. Returns the edited HTML, or
  /// null when cancelled.
  static Future<String?> htmlSource({required String html, bool editable = true}) {
    final TextEditingController controller = TextEditingController(text: _prettyHtml(html));
    return UNavigator.dialog<String>(
      AlertDialog(
        title: Text(U.s.htmlSource),
        content: SizedBox(
          width: 700,
          child: TextField(
            controller: controller,
            readOnly: !editable,
            maxLines: 20,
            minLines: 8,
            style: const TextStyle(fontFamily: "monospace", fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => UClipboard.set(controller.text, snackBar: true), child: Text(U.s.copy)),
          TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
          if (editable) TextButton(onPressed: () => UNavigator.back(controller.text), child: Text(U.s.apply)),
        ],
      ),
    );
  }

  /// Inserts a newline before each top level tag so the source is readable.
  static String _prettyHtml(String html) => html.replaceAllMapped(RegExp(r"<(p|h[1-6]|ul|ol|li|blockquote|pre|figure|hr|table|thead|tbody|tr)\b"), (Match m) => "\n<${m.group(1)}").trim();

  /// Find & replace prompt.
  static Future<UFindReplaceRequest?> findReplace() {
    final TextEditingController find = TextEditingController();
    final TextEditingController replace = TextEditingController();
    bool matchCase = false;
    return UNavigator.dialog<UFindReplaceRequest>(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setInner) => AlertDialog(
          title: Text(U.s.findAndReplace),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: find,
                  autofocus: true,
                  decoration: InputDecoration(labelText: U.s.find, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replace,
                  decoration: InputDecoration(labelText: U.s.replaceWith, border: const OutlineInputBorder()),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: matchCase,
                  title: UTextBodyMedium(U.s.matchCase),
                  onChanged: (bool? v) => setInner(() => matchCase = v ?? false),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
            TextButton(
              onPressed: () => UNavigator.back(UFindReplaceRequest(find: find.text, replace: replace.text, matchCase: matchCase)),
              child: Text(U.s.replaceAll),
            ),
          ],
        ),
      ),
    );
  }

  /// Word / character / reading-time summary for [html].
  static Future<void> documentInfo({required String html}) => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.documentInfo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _infoRow(U.s.words, "${UHtmlDocument.wordCount(html)}"),
          _infoRow(U.s.characters, "${UHtmlDocument.characterCount(html)}"),
          _infoRow(U.s.readingTime, "${UHtmlDocument.readingMinutes(html)} ${U.s.minutes}"),
        ],
      ),
      actions: <Widget>[TextButton(onPressed: UNavigator.back, child: Text(U.s.ok))],
    ),
  );

  static Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: <Widget>[UTextBodyMedium(label).expanded(), UTextBodyMedium(value)]),
  );
}

// =============================================================================
//  EDITOR WIDGET
// =============================================================================

/// Signature for uploading a picked image and returning its final URL (or null
/// on failure). Provide your own to plug in any backend; when omitted the
/// editor uploads through `UServices.media`.
typedef URichImageUploader = Future<String?> Function(FileData file);

/// Embeddable block-based rich text editor.
///
/// Give it a bounded height (e.g. inside an `Expanded` or `SizedBox`).
/// Listen to [onChanged] for the live HTML, or use [URichTextEditor.open] for a
/// ready-made full-screen editing flow that returns the HTML.
class URichTextEditor extends StatefulWidget {
  const URichTextEditor({
    super.key,
    this.initialHtml,
    this.onChanged,
    this.onUploadImage,
    this.onAutoSave,
    this.autoSaveInterval = const Duration(seconds: 20),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.readOnly = false,
    this.showStatusBar = true,
  });

  final String? initialHtml;
  final ValueChanged<String>? onChanged;
  final URichImageUploader? onUploadImage;

  /// Called with the current HTML every [autoSaveInterval] while the document
  /// has unsaved edits.
  final ValueChanged<String>? onAutoSave;
  final Duration autoSaveInterval;
  final EdgeInsets padding;
  final bool readOnly;

  /// Show the word/character count footer.
  final bool showStatusBar;

  /// Push a full-screen editor and await the resulting HTML (null if cancelled).
  static Future<String?> open({String? initialHtml, URichImageUploader? onUploadImage}) =>
      UNavigator.push<String>(_URichTextEditorPage(initialHtml: initialHtml, onUploadImage: onUploadImage), fullscreenDialog: true);

  @override
  State<URichTextEditor> createState() => _URichTextEditorState();
}

class _URichTextEditorState extends State<URichTextEditor> {
  final List<UEditorBlock> _blocks = <UEditorBlock>[];
  final Map<String, TextSelection> _selCache = <String, TextSelection>{};
  final List<String> _history = <String>[];

  int _historyIndex = -1;
  int _activeIndex = 0;
  bool _uploading = false;
  bool _restoring = false;
  bool _dirty = false;
  Timer? _historyTimer;
  Timer? _autoSaveTimer;

  static const List<String> _codeLanguages = <String>["", "dart", "javascript", "typescript", "python", "java", "kotlin", "swift", "csharp", "sql", "json", "yaml", "html", "css", "bash"];

  @override
  void initState() {
    super.initState();
    _blocks.addAll(UHtmlDocument.parse(widget.initialHtml));
    for (final UEditorBlock b in _blocks) _wireBlock(b);
    _history.add(UHtmlDocument.serialize(_blocks));
    _historyIndex = 0;
    if (widget.onAutoSave != null) _autoSaveTimer = Timer.periodic(widget.autoSaveInterval, (_) => _autoSave());
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _autoSaveTimer?.cancel();
    for (final UEditorBlock b in _blocks) b.dispose();
    super.dispose();
  }

  void _autoSave() {
    if (!_dirty) return;
    _dirty = false;
    widget.onAutoSave?.call(_html);
  }

  String get _html => UHtmlDocument.serialize(_blocks);

  void _wireBlock(UEditorBlock b) {
    if (!b.isText) return;
    b.focusNode!.addListener(() {
      if (b.focusNode!.hasFocus) setState(() => _activeIndex = _blocks.indexOf(b));
    });
    b.controller!.addListener(() => _onControllerChanged(b));
    b.focusNode!.onKeyEvent = (FocusNode node, KeyEvent event) => _handleKey(b, event);
  }

  void _onControllerChanged(UEditorBlock b) {
    final TextSelection sel = b.controller!.selection;
    if (sel.isValid) _selCache[b.id] = sel;
    if (mounted) setState(() {});
    _notifyChanged();
  }

  void _notifyChanged() {
    if (_restoring) return;
    _dirty = true;
    widget.onChanged?.call(_html);
    _scheduleHistory();
  }

  // ---- undo / redo ---------------------------------------------------------

  // Snapshots are coalesced so a burst of typing collapses into one undo step.
  void _scheduleHistory() {
    _historyTimer?.cancel();
    _historyTimer = Timer(const Duration(milliseconds: 600), _pushHistory);
  }

  void _pushHistory() {
    final String html = _html;
    if (_historyIndex >= 0 && _historyIndex < _history.length && _history[_historyIndex] == html) return;
    if (_historyIndex < _history.length - 1) _history.removeRange(_historyIndex + 1, _history.length);
    _history.add(html);
    if (_history.length > 100) _history.removeAt(0);
    _historyIndex = _history.length - 1;
    if (mounted) setState(() {});
  }

  bool get _canUndo => _historyIndex > 0;

  bool get _canRedo => _historyIndex >= 0 && _historyIndex < _history.length - 1;

  void _undo() {
    _historyTimer?.cancel();
    _pushHistory();
    if (!_canUndo) return;
    _historyIndex--;
    _loadHtml(_history[_historyIndex]);
  }

  void _redo() {
    if (!_canRedo) return;
    _historyIndex++;
    _loadHtml(_history[_historyIndex]);
  }

  void _loadHtml(String html) {
    _restoring = true;
    setState(() {
      for (final UEditorBlock b in _blocks) b.dispose();
      _blocks
        ..clear()
        ..addAll(UHtmlDocument.parse(html));
      for (final UEditorBlock b in _blocks) _wireBlock(b);
      _activeIndex = 0;
    });
    _restoring = false;
    _dirty = true;
    widget.onChanged?.call(html);
  }

  // ---- selection plumbing --------------------------------------------------

  void _onSelection(void Function(URichTextController c) action) {
    final UEditorBlock? b = _active;
    final URichTextController? c = b?.controller;
    if (b == null || c == null) return;
    if (!c.selection.isValid || c.selection.isCollapsed) {
      final TextSelection? cached = _selCache[b.id];
      if (cached != null && cached.isValid && !cached.isCollapsed) c.selection = cached;
    }
    action(c);
    b.focusNode!.requestFocus();
  }

  UEditorBlock? get _active => (_activeIndex >= 0 && _activeIndex < _blocks.length && _blocks[_activeIndex].isText) ? _blocks[_activeIndex] : null;

  URichTextController? get _activeController => _active?.controller;

  TextSelection? _restoredSelection() {
    final UEditorBlock? b = _active;
    final URichTextController? c = b?.controller;
    if (b == null || c == null) return null;
    if (!c.selection.isValid || c.selection.isCollapsed) {
      final TextSelection? cached = _selCache[b.id];
      if (cached != null && cached.isValid && !cached.isCollapsed) c.selection = cached;
    }
    return c.selection.isValid ? c.selection : null;
  }

  // ---- key handling --------------------------------------------------------

  KeyEventResult _handleKey(UEditorBlock b, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final bool meta = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final bool shift = HardwareKeyboard.instance.isShiftPressed;

    if (meta) {
      final LogicalKeyboardKey key = event.logicalKey;
      if (key == LogicalKeyboardKey.keyB) {
        _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.bold));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyI) {
        _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.italic));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyU) {
        _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.underline));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyK) {
        _editLink();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyF) {
        _findReplace();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyZ) {
        if (shift)
          _redo();
        else
          _undo();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyY) {
        _redo();
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.tab && b.isList) {
      _indent(shift ? -1 : 1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey != LogicalKeyboardKey.backspace) return KeyEventResult.ignored;
    final URichTextController c = b.controller!;
    if (!c.selection.isValid || !c.selection.isCollapsed || c.selection.baseOffset != 0) return KeyEventResult.ignored;
    final int index = _blocks.indexOf(b);
    if (index <= 0) return KeyEventResult.ignored;
    // Outdent first, so backspace at the start of a nested item un-nests it.
    if (b.indent > 0) {
      setState(() => b.indent--);
      _notifyChanged();
      return KeyEventResult.handled;
    }
    _mergeWithPrevious(index);
    return KeyEventResult.handled;
  }

  // ---- block structure operations -----------------------------------------

  void _onChanged(UEditorBlock b, String value) {
    if (_applyMarkdownShortcut(b, value)) return;
    if (!value.contains("\n")) return;
    final int index = _blocks.indexOf(b);
    final int nl = value.indexOf("\n");
    if (b.isList && value.trim().isEmpty) {
      setState(() {
        b.type = UBlockType.paragraph;
        b.indent = 0;
        b.controller!.value = const TextEditingValue();
      });
      _notifyChanged();
      return;
    }
    _splitAtNewline(index, nl);
  }

  // Turns "# ", "- ", "1. ", "> ", "[] " and "```" into the matching block type.
  bool _applyMarkdownShortcut(UEditorBlock b, String value) {
    if (b.type != UBlockType.paragraph) return false;
    UBlockType? type;
    int strip = 0;
    final RegExpMatch? heading = RegExp(r"^(#{1,6})\s").firstMatch(value);
    if (heading != null) {
      const List<UBlockType> levels = <UBlockType>[UBlockType.h1, UBlockType.h2, UBlockType.h3, UBlockType.h4, UBlockType.h5, UBlockType.h6];
      type = levels[heading.group(1)!.length - 1];
      strip = heading.group(0)!.length;
    } else if (value.startsWith("- ") || value.startsWith("* ")) {
      type = UBlockType.bulleted;
      strip = 2;
    } else if (RegExp(r"^\d+[.)]\s").hasMatch(value)) {
      type = UBlockType.numbered;
      strip = RegExp(r"^\d+[.)]\s").firstMatch(value)!.group(0)!.length;
    } else if (value.startsWith("> ")) {
      type = UBlockType.quote;
      strip = 2;
    } else if (value.startsWith("[] ") || value.startsWith("[ ] ")) {
      type = UBlockType.checklist;
      strip = value.startsWith("[] ") ? 3 : 4;
    } else if (value.startsWith("```")) {
      type = UBlockType.code;
      strip = 3;
    } else if (value == "---" || value == "***") {
      setState(() => b.controller!.value = const TextEditingValue());
      _insertBlockAfterActive(UEditorBlock(type: UBlockType.divider));
      return true;
    }
    if (type == null) return false;
    setState(() {
      b.type = type!;
      b.controller!.setContent(value.substring(strip), <UStyleSpan>[], caret: 0);
    });
    _notifyChanged();
    return true;
  }

  void _splitAtNewline(int index, int nl) {
    final UEditorBlock block = _blocks[index];
    final URichTextController c = block.controller!;
    final String full = c.text;
    final String after = full.substring(nl + 1);

    final List<UStyleSpan> afterSpans = <UStyleSpan>[];
    for (final UStyleSpan sp in c.spans) {
      final int s = (sp.start - (nl + 1)).clamp(0, after.length);
      final int e = (sp.end - (nl + 1)).clamp(0, after.length);
      if (e > s) afterSpans.add(UStyleSpan(start: s, end: e, attr: sp.attr, value: sp.value));
    }

    c.value = TextEditingValue(
      text: full.substring(0, nl),
      selection: TextSelection.collapsed(offset: nl),
    );

    final UBlockType nextType = block.isList || block.type == UBlockType.paragraph || block.type == UBlockType.code ? block.type : UBlockType.paragraph;
    final UEditorBlock newBlock = UEditorBlock.text(nextType, text: after, spans: afterSpans, align: block.align, indent: block.indent, language: block.language);

    setState(() => _blocks.insert(index + 1, newBlock));
    _wireBlock(newBlock);
    _notifyChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newBlock.focusNode!.requestFocus();
      newBlock.controller!.selection = const TextSelection.collapsed(offset: 0);
    });
  }

  void _mergeWithPrevious(int index) {
    final UEditorBlock prev = _blocks[index - 1];
    final UEditorBlock cur = _blocks[index];
    if (!prev.isText) {
      setState(() {
        prev.dispose();
        _blocks.removeAt(index - 1);
      });
      _notifyChanged();
      return;
    }
    final URichTextController pc = prev.controller!;
    final URichTextController cc = cur.controller!;
    final int junction = pc.text.length;

    final List<UStyleSpan> merged = <UStyleSpan>[for (final UStyleSpan sp in pc.spans) sp.copy()];
    for (final UStyleSpan sp in cc.spans) merged.add(UStyleSpan(start: sp.start + junction, end: sp.end + junction, attr: sp.attr, value: sp.value));

    pc.setContent(pc.text + cc.text, merged, caret: junction);

    setState(() {
      cur.dispose();
      _blocks.removeAt(index);
      _activeIndex = index - 1;
    });
    _notifyChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      prev.focusNode!.requestFocus();
      pc.selection = TextSelection.collapsed(offset: junction);
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks[index].dispose();
      _blocks.removeAt(index);
      if (_blocks.isEmpty) {
        final UEditorBlock p = UEditorBlock.text(UBlockType.paragraph);
        _blocks.add(p);
        _wireBlock(p);
      }
      _activeIndex = index.clamp(0, _blocks.length - 1);
    });
    _notifyChanged();
  }

  void _duplicateBlock(int index) {
    final UEditorBlock src = _blocks[index];
    final UEditorBlock copy = src.isText
        ? UEditorBlock.text(src.type, text: src.controller!.text, spans: src.controller!.snapshotSpans(), align: src.align, indent: src.indent, checked: src.checked, language: src.language)
        : UEditorBlock(type: src.type, imageUrl: src.imageUrl, imageAlt: src.imageAlt, imageWidth: src.imageWidth, align: src.align, table: src.table?.copy());
    setState(() => _blocks.insert(index + 1, copy));
    _wireBlock(copy);
    _notifyChanged();
  }

  void _moveBlock(int index, int delta) {
    final int target = index + delta;
    if (target < 0 || target >= _blocks.length) return;
    setState(() {
      final UEditorBlock b = _blocks.removeAt(index);
      _blocks.insert(target, b);
      _activeIndex = target;
    });
    _notifyChanged();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final UEditorBlock b = _blocks.removeAt(oldIndex);
      _blocks.insert(target, b);
      _activeIndex = target;
    });
    _notifyChanged();
  }

  void _insertBlockAfterActive(UEditorBlock block) {
    final int at = (_activeIndex + 1).clamp(0, _blocks.length);
    setState(() => _blocks.insert(at, block));
    if (block.isText) _wireBlock(block);
    _notifyChanged();
  }

  // ---- formatting actions --------------------------------------------------

  void _setBlockType(UBlockType type) {
    final UEditorBlock? b = _active;
    if (b == null) return;
    setState(() => b.type = type);
    _notifyChanged();
    b.focusNode!.requestFocus();
  }

  void _setAlign(TextAlign align) {
    final UEditorBlock? b = _blocks.isEmpty ? null : _blocks[_activeIndex.clamp(0, _blocks.length - 1)];
    if (b == null) return;
    setState(() => b.align = align);
    _notifyChanged();
  }

  void _indent(int delta) {
    final UEditorBlock? b = _active;
    if (b == null) return;
    setState(() => b.indent = (b.indent + delta).clamp(0, 8));
    _notifyChanged();
    b.focusNode!.requestFocus();
  }

  Future<void> _pickColor(UInlineAttr attr) async {
    final TextSelection? sel = _restoredSelection();
    final URichTextController? c = _activeController;
    if (sel == null || c == null) return;
    final int? picked = await UEditorDialogs.pickColor(context: context, current: c.activeValue(attr) as int?, title: attr == UInlineAttr.highlight ? U.s.highlightColor : U.s.textColor);
    if (picked == null) return;
    c.selection = sel;
    c.applyValue(attr, picked == 0 ? null : picked);
    _active?.focusNode!.requestFocus();
  }

  Future<void> _editLink() async {
    final TextSelection? sel = _restoredSelection();
    final URichTextController? c = _activeController;
    if (sel == null || c == null) return;
    final String? url = await UEditorDialogs.editLink(existing: c.activeLink());
    if (url == null) return;
    c.selection = sel;
    c.applyValue(UInlineAttr.link, url.trim().isEmpty ? null : url.trim());
    _active?.focusNode!.requestFocus();
  }

  Future<void> _insertTable() async {
    final UTableData? table = await UEditorDialogs.insertTable();
    if (table != null) _insertBlockAfterActive(UEditorBlock(type: UBlockType.table, table: table));
  }

  Future<void> _editHtmlSource() async {
    final String? edited = await UEditorDialogs.htmlSource(html: _html);
    if (edited != null) {
      _loadHtml(edited);
      _pushHistory();
    }
  }

  Future<void> _findReplace() async {
    final UFindReplaceRequest? request = await UEditorDialogs.findReplace();
    if (request == null || request.find.isEmpty) return;
    final Pattern pattern = request.matchCase ? request.find : RegExp(RegExp.escape(request.find), caseSensitive: false);
    int count = 0;
    for (final UEditorBlock b in _blocks) {
      if (b.isText) {
        final String old = b.controller!.text;
        final int hits = pattern.allMatches(old).length;
        if (hits == 0) continue;
        count += hits;
        b.controller!.value = TextEditingValue(text: old.replaceAll(pattern, request.replace), selection: const TextSelection.collapsed(offset: 0));
        continue;
      }
      final UTableData? table = b.table;
      if (table == null) continue;
      for (final List<String> row in table.rows) {
        for (int i = 0; i < row.length; i++) {
          final int hits = pattern.allMatches(row[i]).length;
          if (hits == 0) continue;
          count += hits;
          row[i] = row[i].replaceAll(pattern, request.replace);
        }
      }
    }
    setState(() {});
    _notifyChanged();
    UToast.snackBar(message: count == 0 ? U.s.noMatchesFound : "${U.s.replacedCount}: $count");
  }

  Future<void> _insertImage() async {
    await UFile.showFilePicker(
      allowedExtensions: const <String>["jpg", "jpeg", "png", "gif", "webp"],
      action: (List<FileData> files) async {
        if (files.isEmpty) return;
        setState(() => _uploading = true);
        final URichImageUploader uploader = widget.onUploadImage ?? _defaultUpload;
        final String? url = await uploader(files.first);
        if (!mounted) return;
        setState(() => _uploading = false);
        if (url == null) {
          UToast.error(message: U.s.errorSubmittingForm);
          return;
        }
        _insertBlockAfterActive(UEditorBlock(type: UBlockType.image, imageUrl: url));
      },
    );
  }

  Future<String?> _defaultUpload(FileData file) async {
    final Completer<String?> completer = Completer<String?>();
    await UServices.media.create(
      p: UMediaCreateParams(file: file, tag1: TagMedia.image.number),
      onOk: (UResponse<String> r) => completer.complete(r.message.startsWith("http") ? r.message : r.result),
      onError: (UEmptyResponse e) => completer.complete(null),
      onException: (String e) => completer.complete(null),
    );
    return completer.future;
  }

  void _preview() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.preview),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(child: UHtmlView(html: _html, selectable: true)),
      ),
      actions: <Widget>[TextButton(onPressed: UNavigator.back, child: Text(U.s.ok))],
    ),
  );

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      if (!widget.readOnly) _toolbar(),
      if (_uploading) LinearProgressIndicator(minHeight: 2, color: Theme.of(context).colorScheme.primary),
      const Divider(height: 1),
      ReorderableListView.builder(
        padding: widget.padding,
        buildDefaultDragHandles: false,
        itemCount: _blocks.length,
        onReorder: _reorder,
        itemBuilder: (BuildContext context, int index) => _blockRow(index),
      ).expanded(),
      if (widget.showStatusBar) _statusBar(),
    ],
  );

  Widget _statusBar() {
    final String html = _html;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: <Widget>[
          UTextBodySmall("${U.s.words}: ${UHtmlDocument.wordCount(html)}   ${U.s.characters}: ${UHtmlDocument.characterCount(html)}").expanded(),
          UTextBodySmall("${UHtmlDocument.readingMinutes(html)} ${U.s.minutes}"),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final URichTextController? c = _activeController;
    final Set<UInlineAttr> active = c?.activeAttributes() ?? <UInlineAttr>{};
    final UBlockType type = _active?.type ?? UBlockType.paragraph;
    final Object? family = c?.activeValue(UInlineAttr.fontFamily);
    final Object? size = c?.activeValue(UInlineAttr.fontSize);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          UEditorToolButton(icon: Icons.undo, tooltip: U.s.undo, onTap: _canUndo ? _undo : null),
          UEditorToolButton(icon: Icons.redo, tooltip: U.s.redo, onTap: _canRedo ? _redo : null),
          const UEditorToolSeparator(),
          _blockTypeMenu(type),
          _fontFamilyMenu(family as String?),
          _fontSizeMenu(size as double?),
          const UEditorToolSeparator(),
          UEditorToolButton(
            icon: Icons.format_bold,
            tooltip: U.s.bold,
            active: active.contains(UInlineAttr.bold),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.bold)),
          ),
          UEditorToolButton(
            icon: Icons.format_italic,
            tooltip: U.s.italic,
            active: active.contains(UInlineAttr.italic),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.italic)),
          ),
          UEditorToolButton(
            icon: Icons.format_underlined,
            tooltip: U.s.underline,
            active: active.contains(UInlineAttr.underline),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.underline)),
          ),
          UEditorToolButton(
            icon: Icons.strikethrough_s,
            tooltip: U.s.strikethrough,
            active: active.contains(UInlineAttr.strikethrough),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.strikethrough)),
          ),
          UEditorToolButton(
            icon: Icons.code,
            tooltip: U.s.inlineCode,
            active: active.contains(UInlineAttr.code),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.code)),
          ),
          UEditorToolButton(
            icon: Icons.superscript,
            tooltip: U.s.superscript,
            active: active.contains(UInlineAttr.superscript),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.superscript)),
          ),
          UEditorToolButton(
            icon: Icons.subscript,
            tooltip: U.s.subscript,
            active: active.contains(UInlineAttr.subscript),
            onTap: () => _onSelection((URichTextController c) => c.toggleAttribute(UInlineAttr.subscript)),
          ),
          const UEditorToolSeparator(),
          UEditorToolButton(icon: Icons.format_color_text, tooltip: U.s.textColor, onTap: () => _pickColor(UInlineAttr.color)),
          UEditorToolButton(icon: Icons.border_color_outlined, tooltip: U.s.highlightColor, onTap: () => _pickColor(UInlineAttr.highlight)),
          UEditorToolButton(icon: Icons.link, tooltip: U.s.insertLink, active: c?.activeLink() != null, onTap: _editLink),
          const UEditorToolSeparator(),
          UEditorToolButton(
            icon: Icons.format_list_bulleted,
            tooltip: U.s.bulletedList,
            active: type == UBlockType.bulleted,
            onTap: () => _setBlockType(type == UBlockType.bulleted ? UBlockType.paragraph : UBlockType.bulleted),
          ),
          UEditorToolButton(
            icon: Icons.format_list_numbered,
            tooltip: U.s.numberedList,
            active: type == UBlockType.numbered,
            onTap: () => _setBlockType(type == UBlockType.numbered ? UBlockType.paragraph : UBlockType.numbered),
          ),
          UEditorToolButton(
            icon: Icons.checklist,
            tooltip: U.s.checklist,
            active: type == UBlockType.checklist,
            onTap: () => _setBlockType(type == UBlockType.checklist ? UBlockType.paragraph : UBlockType.checklist),
          ),
          UEditorToolButton(icon: Icons.format_indent_decrease, tooltip: U.s.decreaseIndent, onTap: () => _indent(-1)),
          UEditorToolButton(icon: Icons.format_indent_increase, tooltip: U.s.increaseIndent, onTap: () => _indent(1)),
          const UEditorToolSeparator(),
          UEditorToolButton(icon: Icons.format_align_left, tooltip: U.s.alignLeft, active: _active?.align == TextAlign.left, onTap: () => _setAlign(TextAlign.left)),
          UEditorToolButton(icon: Icons.format_align_center, tooltip: U.s.alignCenter, active: _active?.align == TextAlign.center, onTap: () => _setAlign(TextAlign.center)),
          UEditorToolButton(icon: Icons.format_align_right, tooltip: U.s.alignRight, active: _active?.align == TextAlign.right, onTap: () => _setAlign(TextAlign.right)),
          UEditorToolButton(icon: Icons.format_align_justify, tooltip: U.s.alignJustify, active: _active?.align == TextAlign.justify, onTap: () => _setAlign(TextAlign.justify)),
          const UEditorToolSeparator(),
          UEditorToolButton(icon: Icons.image_outlined, tooltip: U.s.insertImage, onTap: _insertImage),
          UEditorToolButton(icon: Icons.table_chart_outlined, tooltip: U.s.insertTable, onTap: _insertTable),
          UEditorToolButton(
            icon: Icons.horizontal_rule,
            tooltip: U.s.divider,
            onTap: () => _insertBlockAfterActive(UEditorBlock(type: UBlockType.divider)),
          ),
          UEditorToolButton(icon: Icons.format_clear, tooltip: U.s.clearFormatting, onTap: () => _onSelection((URichTextController c) => c.clearFormatting())),
          const UEditorToolSeparator(),
          UEditorToolButton(icon: Icons.find_replace, tooltip: U.s.findAndReplace, onTap: _findReplace),
          UEditorToolButton(icon: Icons.data_object, tooltip: U.s.htmlSource, onTap: _editHtmlSource),
          UEditorToolButton(
            icon: Icons.info_outline,
            tooltip: U.s.documentInfo,
            onTap: () => UEditorDialogs.documentInfo(html: _html),
          ),
          UEditorToolButton(icon: Icons.visibility_outlined, tooltip: U.s.preview, onTap: _preview),
        ].map((Widget w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: w)).toList(),
      ),
    );
  }

  Widget _blockTypeMenu(UBlockType type) => UEditorDropdown<UBlockType>(
    label: UEditorStyles.label(type),
    tooltip: U.s.paragraph,
    width: 130,
    onSelected: _setBlockType,
    items: <UEditorMenuEntry<UBlockType>>[
      for (final UBlockType t in <UBlockType>[
        UBlockType.paragraph,
        UBlockType.h1,
        UBlockType.h2,
        UBlockType.h3,
        UBlockType.h4,
        UBlockType.h5,
        UBlockType.h6,
        UBlockType.quote,
        UBlockType.bulleted,
        UBlockType.numbered,
        UBlockType.checklist,
        UBlockType.code,
      ])
        UEditorMenuEntry<UBlockType>(value: t, label: UEditorStyles.label(t)),
    ],
  );

  Widget _fontFamilyMenu(String? current) => UEditorDropdown<String>(
    label: current ?? U.s.fontFamily,
    tooltip: U.s.fontFamily,
    width: 120,
    onSelected: (String f) => _onSelection((URichTextController c) => c.applyValue(UInlineAttr.fontFamily, f == UEditorStyles.fontFamilies.first ? null : f)),
    items: <UEditorMenuEntry<String>>[
      for (final String f in UEditorStyles.fontFamilies)
        UEditorMenuEntry<String>(
          value: f,
          label: f,
          style: TextStyle(fontFamily: f == UEditorStyles.fontFamilies.first ? null : f),
        ),
    ],
  );

  Widget _fontSizeMenu(double? current) => UEditorDropdown<double>(
    label: current == null ? U.s.fontSize : "${current.toInt()}",
    tooltip: U.s.fontSize,
    width: 78,
    onSelected: (double s) => _onSelection((URichTextController c) => c.applyValue(UInlineAttr.fontSize, s <= 0 ? null : s)),
    items: <UEditorMenuEntry<double>>[
      UEditorMenuEntry<double>(value: 0, label: U.s.none),
      for (final double s in UEditorStyles.fontSizes) UEditorMenuEntry<double>(value: s, label: "${s.toInt()}"),
    ],
  );

  // ---- block rendering -----------------------------------------------------

  Widget _blockRow(int index) {
    final UEditorBlock b = _blocks[index];
    return Padding(
      key: ValueKey<String>(b.id),
      padding: EdgeInsetsDirectional.only(top: 3, bottom: 3, start: b.indent * UHtmlDocument.indentStep),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _blockBody(b).expanded(),
          if (!widget.readOnly) _blockControls(index),
        ],
      ),
    );
  }

  Widget _blockControls(int index) => ReorderableDelayedDragStartListener(
    index: index,
    child: PopupMenuButton<String>(
      icon: Icon(Icons.drag_indicator, size: 18, color: Theme.of(context).colorScheme.outline),
      tooltip: "",
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          onTap: () => _moveBlock(index, -1),
          child: UIconTextHorizontal(leading: const Icon(Icons.arrow_upward, size: 18), trailing: Text(U.s.moveUp)),
        ),
        PopupMenuItem<String>(
          onTap: () => _moveBlock(index, 1),
          child: UIconTextHorizontal(leading: const Icon(Icons.arrow_downward, size: 18), trailing: Text(U.s.moveDown)),
        ),
        PopupMenuItem<String>(
          onTap: () => _duplicateBlock(index),
          child: UIconTextHorizontal(leading: const Icon(Icons.copy_all_outlined, size: 18), trailing: Text(U.s.duplicateBlock)),
        ),
        PopupMenuItem<String>(
          onTap: () => _removeBlock(index),
          child: UIconTextHorizontal(
            leading: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
            trailing: Text(U.s.removeBlock, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
      ],
    ),
  );

  Widget _blockBody(UEditorBlock b) {
    switch (b.type) {
      case UBlockType.image:
        return _imageBlock(b);
      case UBlockType.divider:
        return const Divider(thickness: 2).pSymmetric(vertical: 8);
      case UBlockType.table:
        return _tableBlock(b);
      default:
        return _textBlock(b);
    }
  }

  Widget _textBlock(UEditorBlock b) {
    final TextStyle style = UEditorStyles.baseStyle(context, b.type);
    final Widget field = TextField(
      controller: b.controller,
      focusNode: b.focusNode,
      style: style,
      textAlign: b.align,
      maxLines: null,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.multiline,
      cursorColor: Theme.of(context).colorScheme.primary,
      decoration: InputDecoration.collapsed(
        hintText: U.s.writeSomething,
        hintStyle: style.copyWith(color: Theme.of(context).hintColor),
      ),
      onChanged: (String v) => _onChanged(b, v),
    );

    Widget content = field;
    if (b.isList) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: const EdgeInsetsDirectional.only(top: 2, end: 8, start: 4), child: _listMarker(b, style)),
          field.expanded(),
        ],
      );
    } else if (b.type == UBlockType.code) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[_codeLanguageMenu(b), field],
      );
    }

    return UEditorStyles.decorate(context, b.type, content);
  }

  Widget _listMarker(UEditorBlock b, TextStyle style) {
    if (b.type == UBlockType.checklist) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: b.checked,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (bool? v) {
            setState(() => b.checked = v ?? false);
            _notifyChanged();
          },
        ),
      );
    }
    return Text(b.type == UBlockType.numbered ? "${_listOrdinal(b)}." : "•", style: style);
  }

  Widget _codeLanguageMenu(UEditorBlock b) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: UEditorDropdown<String>(
      label: (b.language ?? "").isEmpty ? U.s.codeLanguage : b.language!,
      tooltip: U.s.codeLanguage,
      onSelected: (String v) {
        setState(() => b.language = v.isEmpty ? null : v);
        _notifyChanged();
      },
      items: <UEditorMenuEntry<String>>[
        for (final String l in _codeLanguages) UEditorMenuEntry<String>(value: l, label: l.isEmpty ? U.s.none : l),
      ],
    ),
  );

  int _listOrdinal(UEditorBlock b) {
    int n = 0;
    for (final UEditorBlock x in _blocks) {
      if (x.type == b.type) n++;
      if (identical(x, b)) break;
      if (x.type != b.type) n = 0;
    }
    return n;
  }

  Widget _tableBlock(UEditorBlock b) {
    b.table ??= UTableData.empty();
    final UTableData table = b.table!;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderSide side = BorderSide(color: cs.outlineVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Table(
          border: TableBorder(top: side, bottom: side, left: side, right: side, horizontalInside: side, verticalInside: side),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            for (int r = 0; r < table.rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: table.hasHeader && r == 0 ? cs.surfaceContainerHighest : null),
                children: <Widget>[
                  for (int col = 0; col < table.rows[r].length; col++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: TextFormField(
                        initialValue: table.rows[r][col],
                        readOnly: widget.readOnly,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: table.hasHeader && r == 0 ? FontWeight.bold : null),
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        onChanged: (String v) {
                          table.rows[r][col] = v;
                          _notifyChanged();
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
        if (!widget.readOnly)
          Row(
            children: <Widget>[
              UEditorToolButton(icon: Icons.add, tooltip: U.s.addRow, size: 16, onTap: () => setState(table.addRow)),
              UEditorToolButton(icon: Icons.add_box_outlined, tooltip: U.s.addColumn, size: 16, onTap: () => setState(table.addColumn)),
              UEditorToolButton(icon: Icons.remove, tooltip: U.s.removeRow, size: 16, onTap: () => setState(() => table.removeRow(table.rowCount - 1))),
              UEditorToolButton(icon: Icons.indeterminate_check_box_outlined, tooltip: U.s.removeColumn, size: 16, onTap: () => setState(() => table.removeColumn(table.columnCount - 1))),
              UEditorToolButton(
                icon: Icons.table_rows_outlined,
                tooltip: U.s.headerRow,
                size: 16,
                active: table.hasHeader,
                onTap: () {
                  setState(() => table.hasHeader = !table.hasHeader);
                  _notifyChanged();
                },
              ),
            ],
          ),
      ],
    ).pSymmetric(vertical: 6);
  }

  Widget _imageBlock(UEditorBlock b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Align(
        alignment: _imageAlignment(b.align),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: UImage(b.imageUrl ?? "", width: b.imageWidth ?? double.infinity, height: 220),
        ),
      ),
      if (!widget.readOnly)
        Row(
          children: <Widget>[
            UEditorToolButton(icon: Icons.format_align_left, tooltip: U.s.alignLeft, size: 16, active: b.align == TextAlign.left, onTap: () => _setImageAlign(b, TextAlign.left)),
            UEditorToolButton(icon: Icons.format_align_center, tooltip: U.s.alignCenter, size: 16, active: b.align == TextAlign.center, onTap: () => _setImageAlign(b, TextAlign.center)),
            UEditorToolButton(icon: Icons.format_align_right, tooltip: U.s.alignRight, size: 16, active: b.align == TextAlign.right, onTap: () => _setImageAlign(b, TextAlign.right)),
            SizedBox(
              width: 140,
              child: Slider(
                value: (b.imageWidth ?? 640).clamp(80, 1200).toDouble(),
                min: 80,
                max: 1200,
                onChanged: (double v) => setState(() => b.imageWidth = v),
                onChangeEnd: (double v) => _notifyChanged(),
              ),
            ),
            UEditorToolButton(icon: Icons.fit_screen_outlined, tooltip: U.s.imageWidth, size: 16, onTap: () => _setImageWidth(b, null)),
          ],
        ),
      TextFormField(
        initialValue: b.imageAlt,
        readOnly: widget.readOnly,
        decoration: InputDecoration(isDense: true, hintText: U.s.imageAltText, border: InputBorder.none),
        style: Theme.of(context).textTheme.bodySmall,
        onChanged: (String v) {
          b.imageAlt = v;
          _notifyChanged();
        },
      ),
    ],
  ).pSymmetric(vertical: 6);

  // Maps a block alignment to a directional alignment so images honour RTL/LTR.
  AlignmentGeometry _imageAlignment(TextAlign align) {
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

  void _setImageAlign(UEditorBlock b, TextAlign align) {
    setState(() => b.align = align);
    _notifyChanged();
  }

  void _setImageWidth(UEditorBlock b, double? width) {
    setState(() => b.imageWidth = width);
    _notifyChanged();
  }
}

/// Full-screen editor page used by [URichTextEditor.open]. Returns the HTML via
/// [UNavigator.back] when the check action is tapped.
class _URichTextEditorPage extends StatefulWidget {
  const _URichTextEditorPage({this.initialHtml, this.onUploadImage});

  final String? initialHtml;
  final URichImageUploader? onUploadImage;

  @override
  State<_URichTextEditorPage> createState() => _URichTextEditorPageState();
}

class _URichTextEditorPageState extends State<_URichTextEditorPage> {
  late String _html = widget.initialHtml ?? "";

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.richTextEditor),
      actions: <Widget>[IconButton(icon: const Icon(Icons.check), tooltip: U.s.submit, onPressed: () => UNavigator.back(_html))],
    ),
    body: URichTextEditor(initialHtml: widget.initialHtml, onUploadImage: widget.onUploadImage, onChanged: (String h) => _html = h),
  );
}
