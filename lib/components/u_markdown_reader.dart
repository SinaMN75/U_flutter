import "package:u/utilities.dart";

final RegExp _reMdEditHeading = RegExp(r"^(#{1,6})[ \t]");
final RegExp _reMdEditFence = RegExp("^ {0,3}(```|~~~)");
final RegExp _reMdEditQuote = RegExp("^ {0,3}>");
final RegExp _reMdEditList = RegExp(r"^([ \t]*)([-+*]|\d{1,9}[.)])([ \t]+)(\[[ xX]\][ \t]+)?");
final RegExp _reMdEditRule = RegExp(r"^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$");
final RegExp _reMdEditInline = RegExp(
  r"(`+[^`\n]+`+)|(\*\*[^*\n]+\*\*|__[^_\n]+__)|(\*[^*\s][^*\n]*\*|(?<![\w])_[^_\s][^_\n]*_(?![\w]))|(~~[^~\n]+~~)|(==[^=\n]+==)|(!?\[[^\]\n]*\]\([^)\n]*\)|\[\^[^\]\n]+\])|(<https?://[^>\s]+>|https?://[^\s)]+)",
);
final RegExp _reMdEditPrefix = RegExp(r"^([ \t]*)(#{1,6}[ \t]+|>[ \t]?|[-+*][ \t]+\[[ xX]\][ \t]+|[-+*][ \t]+|\d{1,9}[.)][ \t]+)");
final RegExp _reMdEditQuotePrefix = RegExp(r"^([ \t]*>[ \t]?)");
final RegExp _reMdEditFootnote = RegExp(r"\[\^(\d+)\]");

/// How the Markdown editor is shown.
enum UMarkdownEditorView { edit, split, preview }

/// Text controller of [UMarkdownEditor]: colours the Markdown syntax while you type.
class UMarkdownEditingController extends TextEditingController {
  UMarkdownEditingController({super.text});

  /// Turn syntax colouring off (e.g. for very long texts).
  bool highlight = true;

  @override
  TextSpan buildTextSpan({required BuildContext context, required bool withComposing, TextStyle? style}) {
    if (!highlight || text.length > 150000 || (withComposing && value.isComposingRangeValid)) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle base = style ?? const TextStyle();
    final double size = base.fontSize ?? 15;
    final TextStyle marker = TextStyle(color: scheme.primary);
    final TextStyle code = TextStyle(fontFamily: "monospace", backgroundColor: scheme.onSurface.withValues(alpha: 0.07), fontSize: size * 0.95);
    final TextStyle link = TextStyle(color: scheme.primary);
    final TextStyle muted = TextStyle(color: scheme.onSurface.withValues(alpha: 0.6));
    final List<InlineSpan> children = <InlineSpan>[];
    final List<String> lines = text.split("\n");
    bool fenced = false;
    for (int l = 0; l < lines.length; l++) {
      final String line = lines[l];
      final String end = l < lines.length - 1 ? "\n" : "";
      if (_reMdEditFence.hasMatch(line)) {
        fenced = !fenced;
        children.add(TextSpan(text: "$line$end", style: code.merge(muted)));
        continue;
      }
      if (fenced) {
        children.add(TextSpan(text: "$line$end", style: code));
        continue;
      }
      final RegExpMatch? heading = _reMdEditHeading.firstMatch(line);
      if (heading != null) {
        final int level = (heading.group(1) ?? "#").length;
        children.add(
          TextSpan(
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * (1.32 - level * 0.05)),
            children: <InlineSpan>[TextSpan(text: heading.group(0), style: marker), ..._inline(line.substring(heading.end), code, link, muted), TextSpan(text: end)],
          ),
        );
        continue;
      }
      if (_reMdEditRule.hasMatch(line)) {
        children.add(TextSpan(text: "$line$end", style: muted));
        continue;
      }
      final RegExpMatch? quote = _reMdEditQuote.firstMatch(line);
      if (quote != null) {
        children.add(
          TextSpan(
            style: muted.copyWith(fontStyle: FontStyle.italic),
            children: <InlineSpan>[TextSpan(text: quote.group(0), style: marker), ..._inline(line.substring(quote.end), code, link, muted), TextSpan(text: end)],
          ),
        );
        continue;
      }
      final RegExpMatch? list = _reMdEditList.firstMatch(line);
      if (list != null) {
        children.add(TextSpan(text: list.group(0), style: marker.copyWith(fontWeight: FontWeight.w700)));
        children.addAll(_inline(line.substring(list.end), code, link, muted));
        children.add(TextSpan(text: end));
        continue;
      }
      children.addAll(_inline(line, code, link, muted));
      children.add(TextSpan(text: end));
    }
    return TextSpan(style: base, children: children);
  }

  static List<InlineSpan> _inline(String line, TextStyle code, TextStyle link, TextStyle muted) {
    final List<InlineSpan> out = <InlineSpan>[];
    int cursor = 0;
    for (final RegExpMatch match in _reMdEditInline.allMatches(line)) {
      if (match.start > cursor) out.add(TextSpan(text: line.substring(cursor, match.start)));
      final String value = match.group(0) ?? "";
      TextStyle style = const TextStyle();
      if (match.group(1) != null) {
        style = code;
      } else if (match.group(2) != null) {
        style = const TextStyle(fontWeight: FontWeight.w700);
      } else if (match.group(3) != null) {
        style = const TextStyle(fontStyle: FontStyle.italic);
      } else if (match.group(4) != null) {
        style = const TextStyle(decoration: TextDecoration.lineThrough);
      } else if (match.group(5) != null) {
        style = const TextStyle(backgroundColor: Color(0x55FFEB3B));
      } else {
        style = link;
      }
      out.add(TextSpan(text: value, style: style));
      cursor = match.end;
    }
    if (cursor < line.length) out.add(TextSpan(text: line.substring(cursor)));
    return out;
  }
}

/// Enter at the end of a list item, task or quote continues it (next number, a fresh `[ ]`); on an empty one it ends it.
/// A formatter, so it runs inside the text input pipeline and works the same with hardware and on-screen keyboards.
class UMarkdownListFormatter extends TextInputFormatter {
  const UMarkdownListFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String text = newValue.text;
    final String before = oldValue.text;
    if (text.length != before.length + 1) return newValue;
    bool insertedAt(int index) => index >= 0 && index < text.length && text[index] == "\n" && text.substring(0, index) == before.substring(0, index) && text.substring(index + 1) == before.substring(index);
    // Prefer the caret; the text alone cannot tell which of several blank lines got the new line, and some keyboards report the caret late.
    final int reported = newValue.selection.isCollapsed ? newValue.selection.baseOffset - 1 : -1;
    int at = reported;
    if (!insertedAt(at)) {
      at = 0;
      while (at < before.length && text.codeUnitAt(at) == before.codeUnitAt(at)) {
        at++;
      }
      while (at > 0 && text[at - 1] == "\n") {
        at--;
      }
      if (!insertedAt(at)) return newValue;
    }
    final int caret = at + 1;
    final int lineStart = at == 0 ? 0 : text.lastIndexOf("\n", at - 1) + 1;
    final String line = text.substring(lineStart, at);
    final RegExpMatch? list = _reMdEditList.firstMatch(line);
    final RegExpMatch? quote = list == null ? _reMdEditQuotePrefix.firstMatch(line) : null;
    final RegExpMatch? match = list ?? quote;
    if (match == null) return newValue;
    final String prefix = match.group(0) ?? "";
    if (line.trim() == prefix.trim()) {
      final String next = text.replaceRange(lineStart, caret, "");
      return TextEditingValue(text: next, selection: TextSelection.collapsed(offset: lineStart));
    }
    String insert = prefix;
    if (list != null) {
      final String marker = list.group(2) ?? "-";
      final int? number = int.tryParse(marker.substring(0, marker.length - 1));
      final String bullet = number != null && marker.length > 1 ? "${number + 1}${marker[marker.length - 1]}" : marker;
      insert = "${list.group(1) ?? ""}$bullet${list.group(3) ?? " "}${list.group(4) != null ? "[ ] " : ""}";
    }
    return TextEditingValue(text: text.replaceRange(caret, caret, insert), selection: TextSelection.collapsed(offset: caret + insert.length));
  }
}

/// Markdown source editor with a formatting toolbar, shortcuts, smart lists, find & replace and statistics.
/// `UMarkdownEditor(initialText: md, onChanged: (String text) => md = text)`
class UMarkdownEditor extends StatefulWidget {
  const UMarkdownEditor({
    this.controller,
    this.initialText = "",
    this.onChanged,
    this.onSave,
    this.onUploadImage,
    this.readOnly = false,
    this.allowCopy = true,
    this.showToolbar = true,
    this.showStatusBar = true,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(16),
    this.hint,
    this.continueLists,
    super.key,
  });

  /// Text controller (created when null).
  final UMarkdownEditingController? controller;

  /// Starting text when no [controller] is given.
  final String initialText;

  /// Called with the text after every change.
  final ValueChanged<String>? onChanged;

  /// Called on Ctrl/Cmd+S.
  final VoidCallback? onSave;

  /// Uploads a picked image and returns its URL; when null the image is embedded as a data URI.
  final Future<String?> Function(UFileData file)? onUploadImage;

  /// Shows the text without allowing edits.
  final bool readOnly;

  /// When false the text cannot be copied or cut.
  final bool allowCopy;

  /// Shows the formatting toolbar.
  final bool showToolbar;

  /// Shows the word/character count footer.
  final bool showStatusBar;

  /// Focuses the field when shown.
  final bool autofocus;

  /// Space around the text.
  final EdgeInsets padding;

  /// Placeholder text.
  final String? hint;

  /// Enter continues lists and quotes. Null: on for desktop and web keyboards, off on phones and tablets,
  /// where on-screen keyboards can type over the inserted marker.
  final bool? continueLists;

  @override
  State<UMarkdownEditor> createState() => UMarkdownEditorState();
}

/// State of [UMarkdownEditor]; use a GlobalKey to run its formatting actions from code.
class UMarkdownEditorState extends State<UMarkdownEditor> {
  late final UMarkdownEditingController _text = widget.controller ?? UMarkdownEditingController(text: widget.initialText);
  late final bool _ownsText = widget.controller == null;
  final UndoHistoryController _undo = UndoHistoryController();
  final FocusNode _focus = FocusNode(debugLabel: "UMarkdownEditor");
  final UDebouncer _stats = UDebouncer(delay: const Duration(milliseconds: 600));
  TextEditingValue _last = TextEditingValue.empty;
  int _words = 0;
  int _characters = 0;

  /// The text controller.
  UMarkdownEditingController get controller => _text;

  /// The undo history of the field.
  UndoHistoryController get undoController => _undo;

  @override
  void initState() {
    super.initState();
    _last = _text.value;
    _text.addListener(_onChanged);
    _undo.addListener(_refresh);
    _count();
  }

  @override
  void dispose() {
    _text.removeListener(_onChanged);
    _undo.removeListener(_refresh);
    _stats.cancel();
    if (_ownsText) _text.dispose();
    _undo.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _count() {
    final String plain = UMarkdown.toPlainText(_text.text);
    _words = plain.split(RegExp(r"\s+")).where((String word) => word.isNotEmpty).length;
    _characters = plain.replaceAll(RegExp(r"\s+"), "").length;
  }

  void _onChanged() {
    final TextEditingValue current = _text.value;
    if (current.text == _last.text) {
      _last = current;
      return;
    }
    _last = current;
    widget.onChanged?.call(_text.text);
    _stats.run(() {
      if (!mounted) return;
      setState(_count);
    });
  }

  void _replace(int start, int end, String insert, {int? caretAt, int? selectFrom, int? selectTo}) {
    if (widget.readOnly) return;
    final String text = _text.text;
    final int a = start.clamp(0, text.length);
    final int b = end.clamp(a, text.length);
    final String next = text.replaceRange(a, b, insert);
    final TextSelection selection = selectFrom != null && selectTo != null
        ? TextSelection(baseOffset: selectFrom, extentOffset: selectTo)
        : TextSelection.collapsed(offset: (caretAt ?? a + insert.length).clamp(0, next.length));
    _text.value = TextEditingValue(text: next, selection: selection);
    if (!_focus.hasFocus && mounted) _focus.requestFocus();
  }

  TextSelection get _selection {
    final TextSelection selection = _text.selection;
    if (selection.isValid) return selection;
    return TextSelection.collapsed(offset: _text.text.length);
  }

  /// Wraps the selection in [before]/[after] (or removes them when already there).
  void wrap(String before, String after, {String placeholder = ""}) {
    final String text = _text.text;
    final TextSelection selection = _selection;
    final int start = selection.start;
    final int end = selection.end;
    if (start >= before.length && end + after.length <= text.length && text.substring(start - before.length, start) == before && text.substring(end, end + after.length) == after) {
      _replace(start - before.length, end + after.length, text.substring(start, end), selectFrom: start - before.length, selectTo: end - before.length);
      return;
    }
    final String inner = start == end ? placeholder : text.substring(start, end);
    _replace(start, end, "$before$inner$after", selectFrom: start + before.length, selectTo: start + before.length + inner.length);
  }

  (int, int) _lineRange() {
    final String text = _text.text;
    final TextSelection selection = _selection;
    final int start = selection.start <= 0 ? 0 : text.lastIndexOf("\n", selection.start - 1) + 1;
    int end = text.indexOf("\n", max(selection.start, selection.end - (selection.end > selection.start && text[selection.end - 1] == "\n" ? 1 : 0)));
    if (end < 0) end = text.length;
    return (start, end);
  }

  void _mapLines(String Function(String line, int index) map) {
    final (int, int) range = _lineRange();
    final List<String> lines = _text.text.substring(range.$1, range.$2).split("\n");
    final String replaced = <String>[for (int i = 0; i < lines.length; i++) map(lines[i], i)].join("\n");
    _replace(range.$1, range.$2, replaced, selectFrom: range.$1, selectTo: range.$1 + replaced.length);
  }

  /// Sets the heading level of the selected lines (0 = paragraph).
  void heading(int level) => _mapLines((String line, int _) {
    final String content = line.replaceFirst(RegExp(r"^ {0,3}#{1,6}[ \t]+"), "");
    return level <= 0 ? content : "${"#" * level} $content";
  });

  /// Toggles a line prefix: "- ", "1. ", "- [ ] " or "> ".
  void linePrefix(String prefix) {
    final (int, int) range = _lineRange();
    final List<String> lines = _text.text.substring(range.$1, range.$2).split("\n");
    final bool numbered = prefix == "1. ";
    bool has(String line) {
      final String trimmed = line.trimLeft();
      if (numbered) return RegExp(r"^\d{1,9}[.)][ \t]").hasMatch(trimmed);
      if (prefix == "- ") return RegExp(r"^[-+*][ \t]").hasMatch(trimmed) && !RegExp(r"^[-+*][ \t]+\[[ xX]\]").hasMatch(trimmed);
      return trimmed.startsWith(prefix.trim());
    }

    final bool remove = lines.where((String line) => line.trim().isNotEmpty).every(has);
    int number = 0;
    _mapLines((String line, int index) {
      if (line.trim().isEmpty) return line;
      final RegExpMatch? existing = _reMdEditPrefix.firstMatch(line);
      final String indent = existing?.group(1) ?? RegExp(r"^[ \t]*").stringMatch(line) ?? "";
      final String content = existing == null ? line.trimLeft() : line.substring(existing.end);
      if (remove) return "$indent$content";
      number++;
      return "$indent${numbered ? "$number. " : prefix}$content";
    });
  }

  /// Indents (or outdents) the selected lines.
  void indent({bool outdent = false}) => _mapLines((String line, int _) {
    if (line.isEmpty) return line;
    final int step = RegExp(r"^[ \t]*\d{1,9}[.)]").hasMatch(line) ? 3 : 2;
    if (!outdent) return "${" " * step}$line";
    final int spaces = RegExp("^ *").stringMatch(line)?.length ?? 0;
    return line.substring(min(spaces, step));
  });

  /// Inserts [block] on its own lines at the caret.
  void insertBlock(String block, {int? selectFrom, int? selectTo}) {
    final String text = _text.text;
    final TextSelection selection = _selection;
    final int start = selection.start;
    final String before = start == 0 || text.substring(0, start).endsWith("\n\n") ? "" : (text.substring(0, start).endsWith("\n") ? "\n" : "\n\n");
    final String after = selection.end >= text.length || text.substring(selection.end).startsWith("\n") ? "\n" : "\n\n";
    final String insert = "$before$block$after";
    final int offset = start + before.length;
    _replace(start, selection.end, insert, selectFrom: selectFrom == null ? null : offset + selectFrom, selectTo: selectTo == null ? null : offset + selectTo, caretAt: offset + block.length);
  }

  /// Wraps the selection in a fenced code block.
  void codeBlock() {
    final TextSelection selection = _selection;
    final String inner = selection.isCollapsed ? "" : _text.text.substring(selection.start, selection.end);
    insertBlock("```\n$inner\n```", selectFrom: 4, selectTo: 4 + inner.length);
  }

  /// Asks for a link and inserts it.
  Future<void> insertLink() async {
    final TextSelection selection = _selection;
    final String selected = selection.isCollapsed ? "" : _text.text.substring(selection.start, selection.end);
    final (String, String)? result = await _twoFields(title: U.s.insertItem(U.s.link), first: U.s.text, firstValue: selected, second: U.s.url, secondValue: "https://");
    if (result == null || result.$2.trim().isEmpty) return;
    final String label = result.$1.trim().isEmpty ? result.$2.trim() : result.$1.trim();
    _replace(selection.start, selection.end, "[$label](${result.$2.trim().replaceAll(" ", "%20")})");
  }

  /// Asks for an image (address or a picked file) and inserts it.
  Future<void> insertImage() async {
    final TextSelection selection = _selection;
    String? url;
    String alt = "";
    final (String, String)? result = await _twoFields(
      title: U.s.insertItem(U.s.image),
      first: U.s.altText,
      second: U.s.url,
      secondValue: "https://",
      extra: (void Function((String, String)) done) => TextButton.icon(
        icon: const Icon(Icons.image_outlined, size: 18),
        label: Text(U.s.selectItem(U.s.file)),
        onPressed: () async {
          final UFileData? file = await UFile.pickSingleImage();
          final Uint8List? bytes = file?.bytes;
          if (file == null || bytes == null) return;
          String? picked;
          final Future<String?> Function(UFileData file)? upload = widget.onUploadImage;
          if (upload != null) {
            ULoading.show();
            try {
              picked = await upload(file);
            } finally {
              ULoading.dismiss();
            }
          } else {
            final String extension = (file.extension ?? "png").toLowerCase();
            picked = "data:image/${extension == "jpg" ? "jpeg" : extension};base64,${base64Encode(bytes)}";
          }
          if (picked != null) done(("", picked));
        },
      ),
    );
    if (result == null) return;
    url = result.$2.trim();
    alt = result.$1.trim();
    if (url.isEmpty || url == "https://") return;
    _replace(selection.start, selection.end, "![$alt](${url.replaceAll(" ", "%20")})");
  }

  /// Asks for a size and inserts an empty table.
  Future<void> insertTable() async {
    final UTableData? table = await UEditorDialogs.insertTable();
    if (table == null) return;
    final int columns = max(1, table.columnCount);
    final List<String> lines = <String>[
      "| ${List<String>.generate(columns, (int index) => "${U.s.title} ${index + 1}").join(" | ")} |",
      "|${List<String>.filled(columns, " --- ").join("|")}|",
      for (int r = 1; r < max(2, table.rowCount); r++) "| ${List<String>.filled(columns, " ").join(" | ")} |",
    ];
    insertBlock(lines.join("\n"));
  }

  /// Inserts a numbered footnote at the caret and its text at the end of the document.
  void insertFootnote() {
    final String text = _text.text;
    int number = 1;
    for (final RegExpMatch match in _reMdEditFootnote.allMatches(text)) {
      number = max(number, (int.tryParse(match.group(1) ?? "") ?? 0) + 1);
    }
    final TextSelection selection = _selection;
    final String reference = "[^$number]";
    final String withReference = text.replaceRange(selection.end, selection.end, reference);
    final String separator = withReference.endsWith("\n\n") ? "" : (withReference.endsWith("\n") ? "\n" : "\n\n");
    final String definition = "[^$number]: ";
    final String placeholder = U.s.footnote;
    final String next = "$withReference$separator$definition$placeholder\n";
    final int start = withReference.length + separator.length + definition.length;
    _text.value = TextEditingValue(text: next, selection: TextSelection(baseOffset: start, extentOffset: start + placeholder.length));
  }

  /// Find & replace over the whole text.
  Future<void> findReplace() async {
    final UFindReplaceRequest? request = await UEditorDialogs.findReplace();
    if (request == null || request.find.isEmpty) return;
    final RegExp pattern = RegExp(RegExp.escape(request.find), caseSensitive: request.matchCase);
    final String next = _text.text.replaceAll(pattern, request.replace);
    if (next != _text.text) _replace(0, _text.text.length, next, caretAt: 0);
  }

  /// Shows words, characters and reading time.
  Future<void> showInfo() => UMarkdownDialogs.info(_text.text);

  Future<(String, String)?> _twoFields({
    required String title,
    required String first,
    required String second,
    String firstValue = "",
    String secondValue = "",
    Widget Function(void Function((String, String)) done)? extra,
  }) {
    final TextEditingController a = TextEditingController(text: firstValue);
    final TextEditingController b = TextEditingController(text: secondValue);
    return UNavigator.dialog<(String, String)>(
      AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: a, autofocus: firstValue.isEmpty, decoration: InputDecoration(labelText: first, border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                controller: b,
                autofocus: firstValue.isNotEmpty,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: second, border: const OutlineInputBorder()),
                onSubmitted: (String _) => UNavigator.back((a.text, b.text)),
              ),
              if (extra != null) Align(alignment: AlignmentDirectional.centerStart, child: extra(((String, String) value) => UNavigator.back((a.text.isEmpty ? value.$1 : a.text, value.$2)))),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back((a.text, b.text)), child: Text(U.s.insert)),
        ],
      ),
    );
  }

  Widget _tool(IconData icon, String tooltip, VoidCallback? onTap) => UEditorToolButton(icon: icon, tooltip: tooltip, onTap: widget.readOnly ? null : onTap);

  Widget _toolbar() => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    child: SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        children: <Widget>[
          _tool(Icons.undo_rounded, U.s.undo, _undo.value.canUndo ? _undo.undo : null),
          _tool(Icons.redo_rounded, U.s.redo, _undo.value.canRedo ? _undo.redo : null),
          const UEditorToolSeparator(),
          PopupMenuButton<int>(
            tooltip: U.s.paragraph,
            enabled: !widget.readOnly,
            onSelected: heading,
            icon: const Icon(Icons.title_rounded, size: 20),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: 0, child: Text(U.s.paragraph)),
              for (int level = 1; level <= 6; level++)
                PopupMenuItem<int>(
                  value: level,
                  child: Text(
                    <String>[U.s.heading1, U.s.heading2, U.s.heading3, U.s.heading4, U.s.heading5, U.s.heading6][level - 1],
                    style: TextStyle(fontSize: 22 - level * 1.6, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          _tool(Icons.format_bold_rounded, U.s.bold, () => wrap("**", "**", placeholder: U.s.bold)),
          _tool(Icons.format_italic_rounded, U.s.italic, () => wrap("*", "*", placeholder: U.s.italic)),
          _tool(Icons.format_strikethrough_rounded, U.s.strikethrough, () => wrap("~~", "~~", placeholder: U.s.strikethrough)),
          _tool(Icons.border_color_outlined, U.s.highlight, () => wrap("==", "==", placeholder: U.s.highlight)),
          _tool(Icons.code_rounded, U.s.inlineCode, () => wrap("`", "`", placeholder: U.s.code)),
          const UEditorToolSeparator(),
          _tool(Icons.format_list_bulleted_rounded, U.s.bulletedList, () => linePrefix("- ")),
          _tool(Icons.format_list_numbered_rounded, U.s.numberedList, () => linePrefix("1. ")),
          _tool(Icons.checklist_rounded, U.s.checklist, () => linePrefix("- [ ] ")),
          _tool(Icons.format_quote_rounded, U.s.quote, () => linePrefix("> ")),
          _tool(Icons.format_indent_increase_rounded, U.s.increaseIndent, indent),
          _tool(Icons.format_indent_decrease_rounded, U.s.decreaseIndent, () => indent(outdent: true)),
          const UEditorToolSeparator(),
          _tool(Icons.link_rounded, U.s.insertItem(U.s.link), () => unawaited(insertLink())),
          _tool(Icons.image_outlined, U.s.insertItem(U.s.image), () => unawaited(insertImage())),
          _tool(Icons.table_chart_outlined, U.s.insertItem(U.s.table), () => unawaited(insertTable())),
          _tool(Icons.data_object_rounded, U.s.codeBlock, codeBlock),
          _tool(Icons.horizontal_rule_rounded, U.s.divider, () => insertBlock("---")),
          _tool(Icons.superscript_rounded, U.s.footnote, insertFootnote),
          const UEditorToolSeparator(),
          _tool(Icons.find_replace_rounded, U.s.findAndReplace, () => unawaited(findReplace())),
          UEditorToolButton(icon: Icons.info_outline_rounded, tooltip: U.s.documentInfo, onTap: () => unawaited(showInfo())),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool rtl = UDocText.isMostlyRtl(_text.text.length > 2000 ? _text.text.substring(0, 2000) : _text.text);
    final Map<ShortcutActivator, VoidCallback> shortcuts = <ShortcutActivator, VoidCallback>{
      for (final bool meta in <bool>[false, true]) ...<ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyB, control: !meta, meta: meta): () => wrap("**", "**", placeholder: U.s.bold),
        SingleActivator(LogicalKeyboardKey.keyI, control: !meta, meta: meta): () => wrap("*", "*", placeholder: U.s.italic),
        SingleActivator(LogicalKeyboardKey.keyK, control: !meta, meta: meta): () => unawaited(insertLink()),
        SingleActivator(LogicalKeyboardKey.keyE, control: !meta, meta: meta): () => wrap("`", "`", placeholder: U.s.code),
        SingleActivator(LogicalKeyboardKey.keyX, control: !meta, meta: meta, shift: true): () => wrap("~~", "~~", placeholder: U.s.strikethrough),
        SingleActivator(LogicalKeyboardKey.keyH, control: !meta, meta: meta, shift: true): () => wrap("==", "==", placeholder: U.s.highlight),
        SingleActivator(LogicalKeyboardKey.keyF, control: !meta, meta: meta, shift: true): () => unawaited(findReplace()),
        SingleActivator(LogicalKeyboardKey.bracketRight, control: !meta, meta: meta): indent,
        SingleActivator(LogicalKeyboardKey.bracketLeft, control: !meta, meta: meta): () => indent(outdent: true),
        if (widget.onSave != null) SingleActivator(LogicalKeyboardKey.keyS, control: !meta, meta: meta): widget.onSave!,
        if (!widget.allowCopy) SingleActivator(LogicalKeyboardKey.keyC, control: !meta, meta: meta): () {},
        if (!widget.allowCopy) SingleActivator(LogicalKeyboardKey.keyX, control: !meta, meta: meta): () {},
      },
    };
    final Widget field = CallbackShortcuts(
      bindings: widget.readOnly ? const <ShortcutActivator, VoidCallback>{} : shortcuts,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        undoController: _undo,
        inputFormatters: widget.continueLists ?? (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android)
            ? const <TextInputFormatter>[UMarkdownListFormatter()]
            : const <TextInputFormatter>[],
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(fontSize: 15, height: 1.55, color: Theme.of(context).colorScheme.onSurface),
        contextMenuBuilder: (BuildContext context, EditableTextState state) {
          final List<ContextMenuButtonItem> items = state.contextMenuButtonItems
              .where((ContextMenuButtonItem item) => widget.allowCopy || (item.type != ContextMenuButtonType.copy && item.type != ContextMenuButtonType.cut && item.type != ContextMenuButtonType.share))
              .toList();
          return AdaptiveTextSelectionToolbar.buttonItems(anchors: state.contextMenuAnchors, buttonItems: items);
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          contentPadding: widget.padding,
          hintText: widget.hint ?? U.s.markdown,
        ),
      ),
    );
    return Column(
      children: <Widget>[
        if (widget.showToolbar && !widget.readOnly) _toolbar(),
        Expanded(child: field),
        if (widget.showStatusBar)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 28,
                child: Row(
                  children: <Widget>[
                    UTextLabelSmall("${U.s.words}: $_words"),
                    const SizedBox(width: 16),
                    UTextLabelSmall("${U.s.characters}: $_characters"),
                    const Spacer(),
                    UTextLabelSmall(U.s.markdown),
                  ],
                ).pSymmetric(horizontal: 12),
              ),
            ),
          ),
      ],
    );
  }
}

/// Dialogs of the Markdown reader and editor.
abstract final class UMarkdownDialogs {
  /// Words, characters, reading time and headings of [markdown].
  static Future<void> info(String markdown) {
    final String plain = UMarkdown.toPlainText(markdown);
    final int words = plain.split(RegExp(r"\s+")).where((String word) => word.isNotEmpty).length;
    final int headings = UMarkdown.layout(markdown).outline.fold(0, (int total, UDocOutlineNode node) => total + 1 + node.descendantCount);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: <Widget>[UTextBodyMedium(label, expanded: 1), UTextBodyMedium(value)]),
    );
    return UNavigator.dialog<void>(
      AlertDialog(
        title: Text(U.s.documentInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            row(U.s.words, "$words"),
            row(U.s.characters, "${plain.replaceAll(RegExp(r"\s+"), "").length}"),
            row(U.s.readingTime, "${max(1, (words / 200).ceil())} ${U.s.min}"),
            row(U.s.contents, "$headings"),
          ],
        ),
        actions: <Widget>[TextButton(onPressed: UNavigator.back, child: Text(U.s.ok))],
      ),
    );
  }
}

/// Full Markdown reader and editor in pure Dart (all platforms), with everything the EPUB/PDF readers have:
/// contents, search, highlights, notes, bookmarks, drawing, reading themes and fonts, paged or scrolled reading,
/// watermark, screenshot blocking and resume position; plus a source editor with live preview, save and export.
/// `UMarkdownReader(filePath: "/docs/readme.md")`
class UMarkdownReader extends StatefulWidget {
  const UMarkdownReader({
    this.text,
    this.bytes,
    this.filePath,
    this.asset,
    this.url,
    this.vaultKey,
    this.storageBucket = UStorageBucket.vault,
    this.headers,
    this.controller,
    this.annotations,
    this.documentId,
    this.title,
    this.chapterLevel = 0,
    this.editable = true,
    this.startInEditor = false,
    this.showToolbar = true,
    this.showBottomBar = true,
    this.showSidebar = true,
    this.showBackButton = false,
    this.allowSelection = true,
    this.allowCopy = true,
    this.allowShare = true,
    this.enableMarkup = true,
    this.enableDrawing = true,
    this.drawController,
    this.markupKinds = UDocMarkupKind.values,
    this.annotationData,
    this.annotationStorageKey,
    this.persistAnnotations = true,
    this.onAnnotationsChanged,
    this.noteDisplay = UDocNoteDisplay.badge,
    this.watermark,
    this.secure = false,
    this.restorePosition = true,
    this.savePath,
    this.onSave,
    this.onChanged,
    this.onUploadImage,
    this.resourceLoader,
    this.baseUrl,
    this.actions = const <Widget>[],
    this.onControllerReady,
    this.onChapterChanged,
    this.onLinkTapped,
    this.onBack,
    super.key,
  }) : assert(text != null || bytes != null || filePath != null || asset != null || url != null || vaultKey != null || controller != null, "Provide one Markdown source");

  /// Markdown text.
  final String? text;

  /// Content as bytes in memory.
  final Uint8List? bytes;

  /// Local file path.
  final String? filePath;

  /// Asset path.
  final String? asset;

  /// Web address of the content.
  final String? url;

  /// UFileStorage key (encrypted vault by default): read in memory, never copied to disk; Save writes back to it.
  final String? vaultKey;

  /// Bucket of [vaultKey].
  final UStorageBucket storageBucket;

  /// HTTP headers for [url] and remote images.
  final Map<String, String>? headers;

  /// Controller to read or change it from code (opened by you or by the reader).
  final UMarkdownController? controller;

  /// Highlights, notes, bookmarks and drawings. Created internally when null.
  final UDocAnnotationController? annotations;

  /// Stable id that progress and annotations are stored under (defaults to the source).
  final String? documentId;

  /// Title text (defaults to the front matter title or the first heading).
  final String? title;

  /// New chapter at every heading of this level or higher (0 = one chapter).
  final int chapterLevel;

  /// Shows the editor (source editing, save and export).
  final bool editable;

  /// Opens in the editor instead of the reader.
  final bool startInEditor;

  /// Shows the top toolbar.
  final bool showToolbar;

  /// Shows the progress bar.
  final bool showBottomBar;

  /// Shows the contents/annotations/search sidebar.
  final bool showSidebar;

  /// Shows a back button.
  final bool showBackButton;

  /// Lets the user select text.
  final bool allowSelection;

  /// When false text can be highlighted but never copied, shared or exported.
  final bool allowCopy;

  /// Allows sharing selected text and exporting the document.
  final bool allowShare;

  /// Allows highlights and notes.
  final bool enableMarkup;

  /// Pen, highlighter, shapes, text boxes and notes drawn over paragraphs.
  final bool enableDrawing;

  /// Tool/style state for drawing.
  final UDocDrawController? drawController;

  /// Which markup tools are offered.
  final List<UDocMarkupKind> markupKinds;

  /// Previously exported annotations (e.g. from a server), merged with the local copy.
  final String? annotationData;

  /// Saves annotations under this key automatically.
  final String? annotationStorageKey;

  /// Keeps annotations between app launches.
  final bool persistAnnotations;

  /// Called with [UDocAnnotationController.export] after every change.
  final void Function(String data)? onAnnotationsChanged;

  /// How notes appear.
  final UDocNoteDisplay noteDisplay;

  /// Watermark text painted over the content.
  final UDocWatermark? watermark;

  /// Blocks screenshots and screen recording while visible.
  final bool secure;

  /// Opens where the user left off.
  final bool restorePosition;

  /// Where Save writes the file (defaults to [filePath]).
  final String? savePath;

  /// Saves the text yourself; return true when it was saved. Wins over [savePath] and [vaultKey].
  final Future<bool> Function(String markdown)? onSave;

  /// Called with the text after every edit.
  final ValueChanged<String>? onChanged;

  /// Uploads an image picked in the editor and returns its URL (else it is embedded as a data URI).
  final Future<String?> Function(UFileData file)? onUploadImage;

  /// Loads images yourself (e.g. from a vault); return null for the default loading.
  final Future<Uint8List?> Function(String href)? resourceLoader;

  /// Web address relative images are resolved against (defaults to the folder of [url]).
  final String? baseUrl;

  /// Extra toolbar buttons.
  final List<Widget> actions;

  /// Gives you the controller once the document is open.
  final void Function(UMarkdownController controller)? onControllerReady;

  /// Called with the new chapter index.
  final void Function(int chapterIndex)? onChapterChanged;

  /// Called first when a link is tapped; return true when you handled it.
  final Future<bool> Function(String href)? onLinkTapped;

  /// Called when the back button is pressed.
  final VoidCallback? onBack;

  @override
  State<UMarkdownReader> createState() => UMarkdownReaderState();
}

/// State of [UMarkdownReader]; use a GlobalKey to switch modes, save or export from code.
class UMarkdownReaderState extends State<UMarkdownReader> {
  late final UMarkdownController _controller = widget.controller ?? UMarkdownController(chapterLevel: widget.chapterLevel);
  late final bool _ownsController = widget.controller == null;
  late final UDocAnnotationController _markup =
      widget.annotations ?? UDocAnnotationController(onChanged: (UDocAnnotationController controller) => widget.onAnnotationsChanged?.call(controller.export()));
  late final bool _ownsMarkup = widget.annotations == null;
  final GlobalKey<UMarkdownEditorState> _editorKey = GlobalKey<UMarkdownEditorState>();
  final UDebouncer _preview = UDebouncer(delay: const Duration(milliseconds: 450));
  UMarkdownEditingController? _source;
  bool _editing = false;
  bool _saving = false;
  bool _ready = false;
  UMarkdownEditorView? _view;

  /// The Markdown controller.
  UMarkdownController get controller => _controller;

  /// Highlights, notes, bookmarks and drawings.
  UDocAnnotationController get annotations => _markup;

  /// The editor is open.
  bool get isEditing => _editing;

  /// There are edits that were not saved.
  bool get isDirty => _controller.isDirty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    unawaited(_open());
  }

  @override
  void dispose() {
    _preview.cancel();
    _controller.removeListener(_onChanged);
    _source?.dispose();
    if (_ownsMarkup) _markup.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _open() async {
    if (!_controller.value.isReady) {
      await _controller.openMarkdown(
        text: widget.text,
        bytes: widget.bytes,
        path: widget.filePath,
        asset: widget.asset,
        url: widget.url,
        storageKey: widget.vaultKey,
        storageBucket: widget.storageBucket,
        headers: widget.headers,
        documentId: widget.documentId,
        baseUrl: widget.baseUrl,
        resourceLoader: widget.resourceLoader,
      );
    }
    if (!mounted || !_controller.value.isReady) return;
    if (_ownsMarkup && widget.persistAnnotations) await _markup.attachStorage(widget.annotationStorageKey ?? "u_doc_markup_${_controller.documentId}");
    final String? remote = widget.annotationData;
    if (remote != null && remote.trim().isNotEmpty) _markup.import(remote, merge: true);
    if (!mounted) return;
    widget.onControllerReady?.call(_controller);
    setState(() => _ready = true);
    if (widget.startInEditor && widget.editable) setEditing(true);
  }

  Future<void> _retry() async {
    setState(() => _ready = false);
    await _open();
  }

  /// Opens (or closes) the editor.
  void setEditing(bool editing) {
    if (!widget.editable || !_ready) return;
    if (editing) {
      final UMarkdownEditingController source = _source ??= UMarkdownEditingController(text: _controller.text);
      if (source.text != _controller.text) source.text = _controller.text;
    } else {
      _applyNow();
    }
    setState(() => _editing = editing);
  }

  void _onSourceChanged(String text) {
    widget.onChanged?.call(text);
    _preview.run(_applyNow);
  }

  void _applyNow() {
    final String? text = _source?.text;
    if (text == null || text == _controller.text) return;
    unawaited(_controller.setText(text, annotations: _markup));
  }

  String get _name {
    final String title = widget.title ?? _controller.value.metadata.title ?? "";
    final String base = title.trim().isEmpty ? "document" : title.trim();
    return base.replaceAll(RegExp(r'[\\/:*?"<>|]+'), "_");
  }

  bool get _canExport => widget.allowCopy && widget.allowShare;

  /// The newest text, including edits the preview has not caught up with yet.
  String get text {
    final String? pending = _source?.text;
    return _editing && pending != null ? pending : _controller.text;
  }

  /// Saves the text (to [UMarkdownReader.onSave], the vault key, [UMarkdownReader.savePath] / the file, or shares it as a file).
  Future<bool> save() async {
    _applyNow();
    final String text = this.text;
    setState(() => _saving = true);
    bool saved = false;
    try {
      final Future<bool> Function(String markdown)? custom = widget.onSave;
      final String? key = widget.vaultKey;
      final String? path = widget.savePath ?? widget.filePath;
      if (custom != null) {
        saved = await custom(text);
      } else if (key != null) {
        await UFileStorage.setBytes(key, utf8.encode(text), bucket: widget.storageBucket, mimeType: "text/markdown");
        saved = true;
      } else if (path != null && !kIsWeb) {
        await File(path).writeAsString(text, flush: true);
        saved = true;
      } else if (_canExport) {
        await UShare.bytes(utf8.encode(text), name: "$_name.md", mimeType: "text/markdown");
        saved = true;
      }
    } on Object {
      saved = false;
    }
    if (!mounted) return saved;
    setState(() => _saving = false);
    if (saved) {
      await _controller.setText(text, annotations: _markup);
      _controller.markSaved();
      UToast.successToast(message: U.s.saved);
    } else {
      UToast.errorToast(message: U.s.somethingWentWrong);
    }
    return saved;
  }

  /// Shares the document as Markdown, HTML or plain text.
  Future<void> export(String format) async {
    if (!_canExport) return;
    final String markdown = text;
    switch (format) {
      case "html":
        await UShare.bytes(utf8.encode(UMarkdown.toHtml(markdown, fullDocument: true, title: widget.title ?? _controller.value.metadata.title)), name: "$_name.html", mimeType: "text/html");
      case "txt":
        await UShare.bytes(utf8.encode(UMarkdown.toPlainText(markdown)), name: "$_name.txt", mimeType: "text/plain");
      default:
        await UShare.bytes(utf8.encode(markdown), name: "$_name.md", mimeType: "text/markdown");
    }
  }

  Future<void> _onMenu(String action) async {
    switch (action) {
      case "save":
        await save();
      case "md":
      case "html":
      case "txt":
        await export(action);
      case "copy":
        await UClipboard.set(text);
        UToast.toast(message: U.s.copied);
      case "copyHtml":
        await UClipboard.set(UMarkdown.toHtml(text));
        UToast.toast(message: U.s.copied);
      case "find":
        await _editorKey.currentState?.findReplace();
      case "info":
        await UMarkdownDialogs.info(text);
    }
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) => PopupMenuItem<String>(
    value: value,
    child: Row(children: <Widget>[Icon(icon, size: 20), const SizedBox(width: 12), Flexible(child: UTextBodyMedium(label))]),
  );

  Widget _fileMenu({required bool editor}) => PopupMenuButton<String>(
    icon: const Icon(Icons.description_outlined),
    tooltip: U.s.file,
    onSelected: (String action) => unawaited(_onMenu(action)),
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      if (widget.editable) _item("save", Icons.save_outlined, U.s.save),
      if (editor) _item("find", Icons.find_replace_rounded, U.s.findAndReplace),
      _item("info", Icons.info_outline_rounded, U.s.documentInfo),
      if (_canExport) ...<PopupMenuEntry<String>>[
        const PopupMenuDivider(),
        _item("md", Icons.ios_share_rounded, U.s.exportAsItem(U.s.markdown)),
        _item("html", Icons.html_rounded, U.s.exportAsItem(U.s.html)),
        _item("txt", Icons.notes_rounded, U.s.exportAsItem(U.s.plainText)),
      ],
      if (widget.allowCopy) ...<PopupMenuEntry<String>>[
        const PopupMenuDivider(),
        _item("copy", Icons.copy_rounded, "${U.s.copy} (${U.s.markdown})"),
        _item("copyHtml", Icons.copy_all_rounded, "${U.s.copy} (${U.s.html})"),
      ],
    ],
  );

  Future<void> _onPop() async {
    final bool? save = await UNavigator.dialog<bool>(
      AlertDialog(
        title: Text(U.s.unsavedChanges),
        content: Text(U.s.doYouWantToSaveYourChanges),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back(false), child: Text(U.s.discard)),
          FilledButton(onPressed: () => UNavigator.back(true), child: Text(U.s.save)),
        ],
      ),
    );
    if (save == null || !mounted) return;
    if (save && !await this.save()) return;
    if (!save) await _controller.revert(annotations: _markup);
    if (!mounted) return;
    final VoidCallback? back = widget.onBack;
    if (back != null) {
      back();
    } else {
      await Navigator.of(context).maybePop();
    }
  }

  void _back() {
    if (_editing) {
      setEditing(false);
      return;
    }
    if (widget.editable && isDirty) {
      unawaited(_onPop());
      return;
    }
    final VoidCallback? back = widget.onBack;
    if (back != null) {
      back();
    } else {
      unawaited(Navigator.of(context).maybePop());
    }
  }

  UEpubReader _reader({required bool preview}) => UEpubReader(
    key: ValueKey<String>(preview ? "preview" : "reader"),
    controller: _controller,
    annotations: _markup,
    title: widget.title,
    showToolbar: !preview && widget.showToolbar,
    showBottomBar: !preview && widget.showBottomBar,
    showSidebar: !preview && widget.showSidebar,
    showBackButton: !preview && (widget.showBackButton || widget.onBack != null),
    allowSelection: widget.allowSelection,
    allowCopy: widget.allowCopy,
    allowShare: widget.allowShare,
    enableMarkup: !preview && widget.enableMarkup,
    enableDrawing: !preview && widget.enableDrawing,
    drawController: preview ? null : widget.drawController,
    markupKinds: widget.markupKinds,
    persistAnnotations: false,
    noteDisplay: widget.noteDisplay,
    watermark: widget.watermark,
    secure: widget.secure,
    restorePosition: !preview && widget.restorePosition,
    onChapterChanged: widget.onChapterChanged,
    onLinkTapped: widget.onLinkTapped,
    onBack: _back,
    actions: preview
        ? const <Widget>[]
        : <Widget>[
            ...widget.actions,
            if (widget.editable) IconButton(icon: const Icon(Icons.edit_note_rounded), tooltip: U.s.edit, onPressed: () => setEditing(true)),
            if (widget.editable && isDirty) IconButton(icon: const Icon(Icons.save_outlined), tooltip: U.s.save, onPressed: _saving ? null : () => unawaited(save())),
            _fileMenu(editor: false),
          ],
  );

  Widget _editorBar(bool wide, UMarkdownEditorView view) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Widget mode(UMarkdownEditorView value, IconData icon, String label) => IconButton(
      icon: Icon(icon),
      tooltip: label,
      isSelected: view == value,
      style: IconButton.styleFrom(backgroundColor: view == value ? scheme.primary.withValues(alpha: 0.14) : null, foregroundColor: view == value ? scheme.primary : null),
      onPressed: () => setState(() {
        _view = value;
        if (value != UMarkdownEditorView.edit) _applyNow();
      }),
    );
    final String title = widget.title ?? _controller.value.metadata.title ?? "";
    return Material(
      color: scheme.surface.withValues(alpha: 0.96),
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: <Widget>[
              IconButton(icon: const Icon(Icons.check_rounded), tooltip: U.s.done, onPressed: () => setEditing(false)),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(child: UTextTitleSmall(title.isEmpty ? U.s.markdown : title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (isDirty) Tooltip(message: U.s.unsavedChanges, child: Icon(Icons.circle, size: 8, color: scheme.primary).pSymmetric(horizontal: 6)),
                  ],
                ),
              ),
              mode(UMarkdownEditorView.edit, Icons.edit_outlined, U.s.edit),
              if (wide) mode(UMarkdownEditorView.split, Icons.vertical_split_outlined, U.s.split),
              mode(UMarkdownEditorView.preview, Icons.visibility_outlined, U.s.preview),
              IconButton(
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                tooltip: U.s.save,
                onPressed: _saving || !isDirty ? null : () => unawaited(save()),
              ),
              _fileMenu(editor: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editorBody() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool wide = constraints.maxWidth >= 900;
      UMarkdownEditorView view = _view ?? (wide ? UMarkdownEditorView.split : UMarkdownEditorView.edit);
      if (!wide && view == UMarkdownEditorView.split) view = UMarkdownEditorView.edit;
      final Widget editor = UMarkdownEditor(
        key: _editorKey,
        controller: _source,
        allowCopy: widget.allowCopy,
        onChanged: _onSourceChanged,
        onSave: () => unawaited(save()),
        onUploadImage: widget.onUploadImage,
      );
      final Widget body = switch (view) {
        UMarkdownEditorView.split => Row(
          children: <Widget>[
            Expanded(child: editor),
            const VerticalDivider(width: 1),
            Expanded(child: _reader(preview: true)),
          ],
        ),
        UMarkdownEditorView.preview => Stack(
          children: <Widget>[
            Offstage(child: editor),
            Positioned.fill(child: _reader(preview: true)),
          ],
        ),
        UMarkdownEditorView.edit => editor,
      };
      final UDocWatermark? watermark = widget.watermark;
      return Column(
        children: <Widget>[
          _editorBar(wide, view),
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: body),
                if (watermark != null && view == UMarkdownEditorView.edit) Positioned.fill(child: UDocWatermarkLayer(watermark: watermark, pageIndex: 0)),
              ],
            ),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final UDocValue value = _controller.value;
    Widget child;
    if (value.hasError) {
      child = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            UTextBodyMedium(U.s.couldNotOpenTheDocument, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => unawaited(_retry()), child: UTextBodyMedium(U.s.retry)),
          ],
        ).pAll(24),
      );
      if (widget.showBackButton || widget.onBack != null) {
        child = Stack(
          children: <Widget>[
            child,
            PositionedDirectional(top: 0, start: 0, child: SafeArea(child: IconButton(icon: const BackButtonIcon(), tooltip: U.s.back, onPressed: _back))),
          ],
        );
      }
    } else if (!_ready) {
      child = const Center(child: CircularProgressIndicator());
    } else if (_editing) {
      child = USecureArea(enabled: widget.secure, child: Material(child: _editorBody()));
    } else {
      child = _reader(preview: false);
    }
    return PopScope(
      canPop: !_editing && !(widget.editable && isDirty),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _back();
      },
      child: child,
    );
  }
}
