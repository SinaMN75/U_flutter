import "package:u/utilities.dart";

final RegExp _reMdFence = RegExp(r"^( {0,3})(`{3,}|~{3,})[ \t]*(.*?)[ \t]*$");
final RegExp _reMdAtx = RegExp(r"^ {0,3}(#{1,6})(?:[ \t]+(.*?))?(?:[ \t]+#+)?[ \t]*$");
final RegExp _reMdRule = RegExp(r"^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$");
final RegExp _reMdSetext = RegExp(r"^ {0,3}(=+|-+)[ \t]*$");
final RegExp _reMdQuote = RegExp(r"^ {0,3}> ?(.*)$");
final RegExp _reMdBullet = RegExp(r"^( {0,3})([-+*])(?:([ \t]+)(.*)|[ \t]*$)");
final RegExp _reMdOrdered = RegExp(r"^( {0,3})(\d{1,9})([.)])(?:([ \t]+)(.*)|[ \t]*$)");
final RegExp _reMdTableDelimiter = RegExp(r"^ {0,3}\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$");
final RegExp _reMdReference = RegExp(r"""^ {0,3}\[([^\]^][^\]]*)\]:[ \t]*<?([^\s>]+)>?(?:[ \t]+(?:"([^"]*)"|'([^']*)'|\(([^)]*)\)))?[ \t]*$""");
final RegExp _reMdFootnote = RegExp(r"^ {0,3}\[\^([^\]]+)\]:[ \t]?(.*)$");
final RegExp _reMdHtmlBlock = RegExp(
  r"^ {0,3}(?:<!--|<\/?(?:address|article|aside|blockquote|center|details|dialog|div|dl|figure|figcaption|footer|form|h[1-6]|header|hr|iframe|main|nav|ol|p|pre|section|summary|table|tbody|td|tfoot|th|thead|tr|ul|video|audio|picture|img)(?:\s|\/?>|$))",
  caseSensitive: false,
);
final RegExp _reMdTask = RegExp(r"^\[([ xX])\](?:[ \t]+|$)");
final RegExp _reMdHeadingId = RegExp(r"[ \t]*\{#([-\w]+)\}[ \t]*$");
final RegExp _reMdWord = RegExp(r"[\p{L}\p{N}]", unicode: true);
final RegExp _reMdSpace = RegExp(r"\s");
final RegExp _reMdSpaces = RegExp(r"\s+");
final RegExp _reMdPunctuation = RegExp(r"""[!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~]""");
final RegExp _reMdAutolink = RegExp(r"^<([A-Za-z][A-Za-z0-9+.\-]{1,31}:[^<>\s]*)>");
final RegExp _reMdEmail = RegExp(r"^<([^\s@<>]+@[^\s@<>]+\.[^\s@<>]+)>");
final RegExp _reMdBareUrl = RegExp(r"""^(?:https?://|www\.)[^\s<]*[^\s<?!.,:;*_~)'"]""");
final RegExp _reMdInlineTag = RegExp(r"^<(/?)([A-Za-z][A-Za-z0-9]*)((?:\s[^<>]*?)?)(/?)>");
final RegExp _reMdAttribute = RegExp(r"""([A-Za-z_:][-\w:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))""");
final RegExp _reMdSlugDrop = RegExp(r"[^\p{L}\p{N}\s_-]", unicode: true);
final RegExp _reMdCode = RegExp(
  r"""(/\*[\s\S]*?\*/|//[^\n]*|<!--[\s\S]*?-->)|("(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`(?:\\.|[^`\\])*`)|(\b(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?)\b)|([A-Za-z_$][\w$]*)""",
);
final RegExp _reMdHashComment = RegExp(r"#[^\n]*");
final RegExp _reMdDashComment = RegExp(r"--[^\n]*");
final RegExp _reMdFrontMatterLine = RegExp(r"^([\w-]+)\s*:\s*(.*)$");
final RegExp _reMdBlankLines = RegExp(r"\n{3,}");
final RegExp _reMdBreakIndent = RegExp(r"  \n +");

/// Kind of a Markdown block.
enum UMarkdownBlockKind { heading, paragraph, code, quote, list, item, table, rule, html, footnote }

/// Kind of a Markdown inline element.
enum UMarkdownInlineKind { text, code, emphasis, strong, strike, highlight, underline, superscript, subscript, keyboard, link, image, lineBreak, footnote }

/// A parsed Markdown block (CommonMark + GitHub tables, task lists and footnotes).
class UMarkdownNode {
  const UMarkdownNode(
    this.kind, {
    this.text = "",
    this.level = 0,
    this.children = const <UMarkdownNode>[],
    this.ordered = false,
    this.start = 1,
    this.checked,
    this.info = "",
    this.rows = const <List<String>>[],
    this.aligns = const <TextAlign?>[],
    this.id = "",
  });

  final UMarkdownBlockKind kind;

  /// Inline Markdown of a heading or paragraph, the code of a code block, or raw HTML.
  final String text;

  /// Heading level (1–6).
  final int level;

  /// Blocks inside a quote, list, list item or footnote.
  final List<UMarkdownNode> children;

  /// Numbered list.
  final bool ordered;

  /// First number of a numbered list.
  final int start;

  /// Task list item state (null for a normal item).
  final bool? checked;

  /// Language of a fenced code block.
  final String info;

  /// Table cells as inline Markdown; the first row is the header.
  final List<List<String>> rows;

  /// Column alignment of a table.
  final List<TextAlign?> aligns;

  /// Anchor of a heading, or the label of a footnote.
  final String id;
}

/// A parsed Markdown inline element.
class UMarkdownInline {
  const UMarkdownInline(this.kind, {this.text = "", this.children = const <UMarkdownInline>[], this.href = "", this.title = ""});

  final UMarkdownInlineKind kind;

  /// Text, code, image alt text or footnote label.
  final String text;

  final List<UMarkdownInline> children;

  /// Link or image address.
  final String href;

  final String title;

  String get plainText {
    switch (kind) {
      case UMarkdownInlineKind.text:
      case UMarkdownInlineKind.code:
      case UMarkdownInlineKind.image:
        return text;
      case UMarkdownInlineKind.lineBreak:
        return "\n";
      case UMarkdownInlineKind.footnote:
        return "";
      default:
        return children.map((UMarkdownInline child) => child.plainText).join();
    }
  }
}

/// A whole parsed Markdown document.
class UMarkdownTree {
  const UMarkdownTree({required this.blocks, required this.references, required this.footnotes, required this.frontMatter});

  final List<UMarkdownNode> blocks;

  /// Link reference definitions: label → (url, title).
  final Map<String, (String, String)> references;

  /// Footnote definitions in reference order.
  final List<UMarkdownNode> footnotes;

  /// Keys of a leading YAML front matter block (title, author, lang, dir…).
  final Map<String, String> frontMatter;

  /// Number shown for a footnote label (1-based), or 0.
  int footnoteNumber(String label) => footnotes.indexWhere((UMarkdownNode node) => node.id == label) + 1;
}

/// Markdown tools: parse, convert to reader blocks, HTML or plain text, and back from HTML.
abstract final class UMarkdown {
  /// Parses [source] into blocks.
  static UMarkdownTree parse(String source) => _UMarkdownParser().parseDocument(source);

  /// Parses the inline Markdown of one paragraph.
  static List<UMarkdownInline> parseInline(String text, {UMarkdownTree? tree}) => _UMarkdownInlineParser(tree).parse(text);

  /// GitHub style anchor of a heading.
  static String slug(String text) => text.trim().toLowerCase().replaceAll(_reMdSlugDrop, "").replaceAll(_reMdSpaces, "-");

  /// Text without any Markdown syntax.
  static String toPlainText(String source) {
    final UMarkdownTree tree = parse(source);
    final StringBuffer buffer = StringBuffer();
    void walk(List<UMarkdownNode> nodes) {
      for (final UMarkdownNode node in nodes) {
        switch (node.kind) {
          case UMarkdownBlockKind.heading:
          case UMarkdownBlockKind.paragraph:
            buffer.writeln(parseInline(node.text, tree: tree).map((UMarkdownInline inline) => inline.plainText).join());
            buffer.writeln();
          case UMarkdownBlockKind.code:
            buffer.writeln(node.text);
            buffer.writeln();
          case UMarkdownBlockKind.table:
            for (final List<String> row in node.rows) {
              buffer.writeln(row.map((String cell) => parseInline(cell, tree: tree).map((UMarkdownInline inline) => inline.plainText).join()).join("\t"));
            }
            buffer.writeln();
          case UMarkdownBlockKind.html:
            buffer.writeln(UEpubXml.parse(node.text)?.textContent.trim() ?? "");
          case UMarkdownBlockKind.rule:
            buffer.writeln();
          case UMarkdownBlockKind.quote:
          case UMarkdownBlockKind.list:
          case UMarkdownBlockKind.item:
          case UMarkdownBlockKind.footnote:
            walk(node.children);
        }
      }
    }

    walk(tree.blocks);
    walk(tree.footnotes);
    return buffer.toString().replaceAll(_reMdBlankLines, "\n\n").trim();
  }

  /// Number of words.
  static int wordCount(String source) => toPlainText(source).split(_reMdSpaces).where((String word) => word.isNotEmpty).length;

  /// Number of characters without Markdown syntax.
  static int characterCount(String source) => toPlainText(source).replaceAll(_reMdSpaces, "").length;

  /// Estimated reading time in minutes.
  static int readingMinutes(String source, {int wordsPerMinute = 200}) => max(1, (wordCount(source) / wordsPerMinute).ceil());

  /// HTML of [source]. With [fullDocument] a complete page with basic styles is returned.
  static String toHtml(String source, {bool fullDocument = false, String? title}) {
    final UMarkdownTree tree = parse(source);
    final String body = _UMarkdownHtml(tree).render();
    if (!fullDocument) return body;
    final String pageTitle = title ?? tree.frontMatter["title"] ?? "";
    final String plain = toPlainText(source);
    final bool rtl = (tree.frontMatter["dir"] ?? "").toLowerCase() == "rtl" || UDocText.isMostlyRtl(plain.length > 4000 ? plain.substring(0, 4000) : plain);
    return """<!DOCTYPE html>
<html${rtl ? ' dir="rtl"' : ""}>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_escape(pageTitle)}</title>
<style>
body{font-family:-apple-system,"Segoe UI",Roboto,Vazirmatn,Tahoma,sans-serif;line-height:1.65;max-width:820px;margin:32px auto;padding:0 16px;color:#1f2328}
pre{background:#f6f8fa;padding:12px;border-radius:6px;overflow:auto}code{font-family:ui-monospace,Menlo,Consolas,monospace;background:#f6f8fa;padding:2px 4px;border-radius:4px}pre code{padding:0}
blockquote{margin:0;padding:0 1em;color:#59636e;border-inline-start:4px solid #d1d9e0}table{border-collapse:collapse}th,td{border:1px solid #d1d9e0;padding:6px 12px}
img{max-width:100%}mark{background:#fff3a3}hr{border:0;border-top:1px solid #d1d9e0}li.task{list-style:none}
</style>
</head>
<body>
$body
</body>
</html>
""";
  }

  /// Markdown of an HTML fragment or page (headings, emphasis, links, images, lists, quotes, code, tables).
  static String fromHtml(String html) {
    final UEpubNode? root = UEpubXml.parse(html);
    if (root == null) return "";
    UEpubNode start = root;
    for (final UEpubNode body in root.findAll("body")) {
      start = body;
      break;
    }
    return _UMarkdownFromHtml().blocks(start.children, 0).replaceAll(_reMdBreakIndent, "  \n").replaceAll(_reMdBlankLines, "\n\n").trim();
  }

  /// Turns [source] into reader chapters. [chapterLevel] starts a new chapter at every heading of that level or higher (0 = one chapter).
  static UMarkdownLayout layout(String source, {int chapterLevel = 0}) => _UMarkdownBlockBuilder(parse(source)).layout(chapterLevel);

  static String _escape(String text) => text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("\"", "&quot;");
}

/// Reader blocks of a Markdown document split into chapters.
class UMarkdownLayout {
  const UMarkdownLayout({required this.chapters, required this.outline, required this.anchors, required this.metadata, required this.direction});

  final List<UEpubChapter> chapters;

  /// Headings as a table of contents.
  final List<UDocOutlineNode> outline;

  /// Heading or footnote anchor → chapter index.
  final Map<String, int> anchors;

  final UDocMetadata metadata;

  final UDocDirection direction;
}

class _UMarkdownParser {
  final Map<String, (String, String)> references = <String, (String, String)>{};
  final Map<String, UMarkdownNode> footnotes = <String, UMarkdownNode>{};
  int _depth = 0;

  UMarkdownTree parseDocument(String source) {
    String text = source.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
    if (text.startsWith("﻿")) text = text.substring(1);
    final Map<String, String> frontMatter = <String, String>{};
    if (text.startsWith("---\n")) {
      final int end = text.indexOf("\n---", 4);
      if (end > 0 && (end + 4 == text.length || text[end + 4] == "\n")) {
        for (final String line in text.substring(4, end).split("\n")) {
          final RegExpMatch? match = _reMdFrontMatterLine.firstMatch(line.trim());
          if (match == null) continue;
          String value = (match.group(2) ?? "").trim();
          if (value.length >= 2 && ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'")))) value = value.substring(1, value.length - 1);
          frontMatter[(match.group(1) ?? "").toLowerCase()] = value;
        }
        text = text.substring(min(text.length, end + 5));
      }
    }
    final List<String> lines = text.split("\n").map(_expandTabs).toList();
    _collectDefinitions(lines);
    final List<UMarkdownNode> blocks = parse(lines);
    return UMarkdownTree(blocks: _assignIds(blocks), references: references, footnotes: footnotes.values.toList(), frontMatter: frontMatter);
  }

  static String _expandTabs(String line) {
    if (!line.contains("\t")) return line;
    final StringBuffer buffer = StringBuffer();
    int column = 0;
    int i = 0;
    while (i < line.length && (line[i] == " " || line[i] == "\t")) {
      if (line[i] == "\t") {
        final int spaces = 4 - column % 4;
        buffer.write(" " * spaces);
        column += spaces;
      } else {
        buffer.write(" ");
        column++;
      }
      i++;
    }
    buffer.write(line.substring(i));
    return buffer.toString();
  }

  void _collectDefinitions(List<String> lines) {
    bool inFence = false;
    String fence = "";
    for (int i = 0; i < lines.length; i++) {
      final RegExpMatch? fenceMatch = _reMdFence.firstMatch(lines[i]);
      if (fenceMatch != null) {
        final String marker = fenceMatch.group(2) ?? "";
        if (!inFence) {
          inFence = true;
          fence = marker;
        } else if (marker[0] == fence[0] && marker.length >= fence.length && (fenceMatch.group(3) ?? "").isEmpty) {
          inFence = false;
        }
        continue;
      }
      if (inFence) continue;
      final RegExpMatch? match = _reMdReference.firstMatch(lines[i]);
      if (match == null) continue;
      final String label = _label(match.group(1) ?? "");
      references.putIfAbsent(label, () => (match.group(2) ?? "", match.group(3) ?? match.group(4) ?? match.group(5) ?? ""));
    }
  }

  static String _label(String label) => label.trim().toLowerCase().replaceAll(_reMdSpaces, " ");

  static bool _blank(String line) => line.trim().isEmpty;

  static int _indent(String line) {
    int count = 0;
    while (count < line.length && line[count] == " ") {
      count++;
    }
    return count;
  }

  List<UMarkdownNode> _assignIds(List<UMarkdownNode> blocks) {
    final Map<String, int> used = <String, int>{};
    UMarkdownNode visit(UMarkdownNode node) {
      if (node.kind == UMarkdownBlockKind.heading) {
        String id = node.id;
        if (id.isEmpty) {
          final String base = UMarkdown.slug(UMarkdown.parseInline(node.text).map((UMarkdownInline inline) => inline.plainText).join());
          final int seen = used[base] ?? 0;
          used[base] = seen + 1;
          id = seen == 0 ? base : "$base-$seen";
        }
        return UMarkdownNode(UMarkdownBlockKind.heading, text: node.text, level: node.level, id: id);
      }
      if (node.children.isEmpty) return node;
      return UMarkdownNode(node.kind, text: node.text, level: node.level, children: node.children.map(visit).toList(), ordered: node.ordered, start: node.start, checked: node.checked, id: node.id);
    }

    return blocks.map(visit).toList();
  }

  bool _interrupts(String line) {
    if (_reMdAtx.hasMatch(line) || _reMdFence.hasMatch(line) || _reMdRule.hasMatch(line) || _reMdQuote.hasMatch(line) || _reMdHtmlBlock.hasMatch(line)) return true;
    final RegExpMatch? bullet = _reMdBullet.firstMatch(line);
    if (bullet != null && (bullet.group(4) ?? "").trim().isNotEmpty) return true;
    final RegExpMatch? ordered = _reMdOrdered.firstMatch(line);
    return ordered != null && ordered.group(2) == "1" && (ordered.group(5) ?? "").trim().isNotEmpty;
  }

  List<UMarkdownNode> parse(List<String> lines) {
    final List<UMarkdownNode> out = <UMarkdownNode>[];
    if (++_depth > 40) {
      _depth--;
      return <UMarkdownNode>[UMarkdownNode(UMarkdownBlockKind.paragraph, text: lines.join("\n"))];
    }
    int i = 0;
    while (i < lines.length) {
      final String line = lines[i];
      if (_blank(line)) {
        i++;
        continue;
      }
      final RegExpMatch? fence = _reMdFence.firstMatch(line);
      if (fence != null && !(fence.group(2)!.startsWith("`") && (fence.group(3) ?? "").contains("`"))) {
        final int indent = (fence.group(1) ?? "").length;
        final String marker = fence.group(2) ?? "";
        final List<String> code = <String>[];
        i++;
        while (i < lines.length) {
          final RegExpMatch? close = _reMdFence.firstMatch(lines[i]);
          if (close != null && (close.group(2) ?? "")[0] == marker[0] && (close.group(2) ?? "").length >= marker.length && (close.group(3) ?? "").isEmpty) {
            i++;
            break;
          }
          final String content = lines[i];
          code.add(content.substring(min(indent, _indent(content))));
          i++;
        }
        out.add(UMarkdownNode(UMarkdownBlockKind.code, text: code.join("\n"), info: (fence.group(3) ?? "").split(" ").first.toLowerCase()));
        continue;
      }
      final RegExpMatch? atx = _reMdAtx.firstMatch(line);
      if (atx != null) {
        String content = atx.group(2) ?? "";
        String id = "";
        final RegExpMatch? custom = _reMdHeadingId.firstMatch(content);
        if (custom != null) {
          id = custom.group(1) ?? "";
          content = content.substring(0, custom.start);
        }
        out.add(UMarkdownNode(UMarkdownBlockKind.heading, text: content.trim(), level: (atx.group(1) ?? "#").length, id: id));
        i++;
        continue;
      }
      if (_reMdRule.hasMatch(line)) {
        out.add(const UMarkdownNode(UMarkdownBlockKind.rule));
        i++;
        continue;
      }
      if (_reMdReference.hasMatch(line)) {
        i++;
        continue;
      }
      final RegExpMatch? footnote = _reMdFootnote.firstMatch(line);
      if (footnote != null) {
        final List<String> body = <String>[footnote.group(2) ?? ""];
        i++;
        while (i < lines.length) {
          if (_blank(lines[i])) {
            int j = i;
            while (j < lines.length && _blank(lines[j])) {
              j++;
            }
            if (j < lines.length && _indent(lines[j]) >= 4) {
              body.addAll(List<String>.filled(j - i, ""));
              i = j;
              continue;
            }
            break;
          }
          if (_indent(lines[i]) >= 4) {
            body.add(lines[i].substring(4));
          } else if (_interrupts(lines[i]) || _reMdFootnote.hasMatch(lines[i])) {
            break;
          } else {
            body.add(lines[i].trim());
          }
          i++;
        }
        final String label = footnote.group(1) ?? "";
        footnotes.putIfAbsent(label, () => UMarkdownNode(UMarkdownBlockKind.footnote, id: label, children: parse(body)));
        continue;
      }
      if (_reMdQuote.hasMatch(line)) {
        final List<String> body = <String>[];
        while (i < lines.length) {
          final RegExpMatch? quote = _reMdQuote.firstMatch(lines[i]);
          if (quote != null) {
            body.add(quote.group(1) ?? "");
          } else if (!_blank(lines[i]) && body.isNotEmpty && !_blank(body.last) && !_interrupts(lines[i])) {
            body.add(lines[i]);
          } else {
            break;
          }
          i++;
        }
        out.add(UMarkdownNode(UMarkdownBlockKind.quote, children: parse(body)));
        continue;
      }
      if (_reMdBullet.hasMatch(line) || _reMdOrdered.hasMatch(line)) {
        i = _parseList(lines, i, out);
        continue;
      }
      if (_indent(line) >= 4) {
        final List<String> code = <String>[];
        while (i < lines.length && (_indent(lines[i]) >= 4 || _blank(lines[i]))) {
          code.add(_blank(lines[i]) ? "" : lines[i].substring(4));
          i++;
        }
        while (code.isNotEmpty && code.last.isEmpty) {
          code.removeLast();
        }
        out.add(UMarkdownNode(UMarkdownBlockKind.code, text: code.join("\n")));
        continue;
      }
      if (_reMdHtmlBlock.hasMatch(line)) {
        final List<String> html = <String>[];
        while (i < lines.length && !_blank(lines[i])) {
          html.add(lines[i]);
          i++;
        }
        out.add(UMarkdownNode(UMarkdownBlockKind.html, text: html.join("\n")));
        continue;
      }
      if (line.contains("|") && i + 1 < lines.length && _reMdTableDelimiter.hasMatch(lines[i + 1]) && lines[i + 1].contains(RegExp("[|:]"))) {
        final List<String> delimiters = _cells(lines[i + 1]);
        final List<TextAlign?> aligns = delimiters.map((String cell) {
          final String value = cell.trim();
          if (value.startsWith(":") && value.endsWith(":")) return TextAlign.center;
          if (value.endsWith(":")) return TextAlign.end;
          if (value.startsWith(":")) return TextAlign.start;
          return null;
        }).toList();
        final List<List<String>> rows = <List<String>>[_cells(line)];
        i += 2;
        while (i < lines.length && !_blank(lines[i]) && lines[i].contains("|") && !_interrupts(lines[i])) {
          rows.add(_cells(lines[i]));
          i++;
        }
        final int columns = rows.fold(aligns.length, (int value, List<String> row) => max(value, row.length));
        out.add(
          UMarkdownNode(
            UMarkdownBlockKind.table,
            rows: rows.map((List<String> row) => <String>[...row, ...List<String>.filled(columns - row.length, "")]).toList(),
            aligns: <TextAlign?>[...aligns, ...List<TextAlign?>.filled(max(0, columns - aligns.length), null)],
          ),
        );
        continue;
      }
      final List<String> paragraph = <String>[line.trim()];
      i++;
      int? setext;
      while (i < lines.length && !_blank(lines[i])) {
        final RegExpMatch? underline = _reMdSetext.firstMatch(lines[i]);
        if (underline != null) {
          setext = (underline.group(1) ?? "=").startsWith("=") ? 1 : 2;
          i++;
          break;
        }
        if (_interrupts(lines[i])) break;
        paragraph.add(lines[i].trimLeft());
        i++;
      }
      final String content = paragraph.join("\n");
      if (setext != null) {
        out.add(UMarkdownNode(UMarkdownBlockKind.heading, text: content.trim(), level: setext));
      } else {
        out.add(UMarkdownNode(UMarkdownBlockKind.paragraph, text: content));
      }
    }
    _depth--;
    return out;
  }

  static List<String> _cells(String line) {
    String row = line.trim();
    if (row.startsWith("|")) row = row.substring(1);
    if (row.endsWith("|") && !row.endsWith("\\|")) row = row.substring(0, row.length - 1);
    final List<String> cells = <String>[];
    final StringBuffer cell = StringBuffer();
    bool code = false;
    for (int i = 0; i < row.length; i++) {
      final String character = row[i];
      if (character == "\\" && i + 1 < row.length && row[i + 1] == "|") {
        cell.write("|");
        i++;
        continue;
      }
      if (character == "`") code = !code;
      if (character == "|" && !code) {
        cells.add(cell.toString().trim());
        cell.clear();
        continue;
      }
      cell.write(character);
    }
    cells.add(cell.toString().trim());
    return cells;
  }

  int _parseList(List<String> lines, int start, List<UMarkdownNode> out) {
    int i = start;
    final RegExpMatch? first = _reMdBullet.firstMatch(lines[i]);
    final RegExpMatch? firstOrdered = first == null ? _reMdOrdered.firstMatch(lines[i]) : null;
    final bool ordered = first == null;
    final String marker = ordered ? (firstOrdered?.group(3) ?? ".") : (first.group(2) ?? "-");
    final int baseIndent = ((ordered ? firstOrdered?.group(1) : first.group(1)) ?? "").length;
    final int number = ordered ? int.tryParse(firstOrdered?.group(2) ?? "1") ?? 1 : 1;
    final List<UMarkdownNode> items = <UMarkdownNode>[];
    while (i < lines.length) {
      final RegExpMatch? match = ordered ? _reMdOrdered.firstMatch(lines[i]) : _reMdBullet.firstMatch(lines[i]);
      if (match == null || _reMdRule.hasMatch(lines[i]) && !ordered) break;
      if ((ordered ? match.group(3) : match.group(2)) != marker) break;
      final int indent = (match.group(1) ?? "").length;
      if (indent > baseIndent + 3) break;
      final String markerText = ordered ? "${match.group(2)}${match.group(3)}" : (match.group(2) ?? "");
      final String gap = (ordered ? match.group(4) : match.group(3)) ?? " ";
      final String content = (ordered ? match.group(5) : match.group(4)) ?? "";
      final int contentIndent = indent + markerText.length + (gap.length > 4 || content.isEmpty ? 1 : gap.length);
      final String head = gap.length > 4 ? "${" " * (gap.length - 1)}$content" : content;
      final List<String> body = <String>[head];
      i++;
      while (i < lines.length) {
        final String line = lines[i];
        if (_blank(line)) {
          int j = i;
          while (j < lines.length && _blank(lines[j])) {
            j++;
          }
          if (j < lines.length && _indent(lines[j]) >= contentIndent) {
            body.addAll(List<String>.filled(j - i, ""));
            i = j;
            continue;
          }
          break;
        }
        if (_indent(line) >= contentIndent) {
          body.add(line.substring(contentIndent));
          i++;
          continue;
        }
        if (_reMdBullet.hasMatch(line) || _reMdOrdered.hasMatch(line) || _interrupts(line) || _blank(body.last)) break;
        body.add(line.trimLeft());
        i++;
      }
      bool? checked;
      final RegExpMatch? task = _reMdTask.firstMatch(body.first);
      if (task != null) {
        checked = (task.group(1) ?? " ") != " ";
        body[0] = body.first.substring(task.end);
      }
      items.add(UMarkdownNode(UMarkdownBlockKind.item, children: parse(body), checked: checked));
      int j = i;
      while (j < lines.length && _blank(lines[j])) {
        j++;
      }
      if (j >= lines.length) {
        i = j;
        break;
      }
      final RegExpMatch? next = ordered ? _reMdOrdered.firstMatch(lines[j]) : _reMdBullet.firstMatch(lines[j]);
      if (next == null || (ordered ? next.group(3) : next.group(2)) != marker || _indent(lines[j]) > baseIndent + 3 || (!ordered && _reMdRule.hasMatch(lines[j]))) break;
      i = j;
    }
    out.add(UMarkdownNode(UMarkdownBlockKind.list, ordered: ordered, start: number, children: items));
    return i;
  }
}

class _UMarkdownInlineParser {
  _UMarkdownInlineParser(this.tree);

  final UMarkdownTree? tree;
  int _depth = 0;

  static bool _isSpace(String? character) => character == null || _reMdSpace.hasMatch(character);

  static bool _isWord(String? character) => character != null && _reMdWord.hasMatch(character);

  List<UMarkdownInline> parse(String source, {bool links = true}) {
    final List<UMarkdownInline> out = <UMarkdownInline>[];
    if (++_depth > 24) {
      _depth--;
      return <UMarkdownInline>[UMarkdownInline(UMarkdownInlineKind.text, text: source)];
    }
    final StringBuffer text = StringBuffer();
    void flush() {
      if (text.isEmpty) return;
      out.add(UMarkdownInline(UMarkdownInlineKind.text, text: text.toString()));
      text.clear();
    }

    void add(UMarkdownInline inline) {
      flush();
      out.add(inline);
    }

    int i = 0;
    final int length = source.length;
    while (i < length) {
      final String c = source[i];
      if (c == "\\" && i + 1 < length) {
        final String next = source[i + 1];
        if (next == "\n") {
          add(const UMarkdownInline(UMarkdownInlineKind.lineBreak));
          i += 2;
          continue;
        }
        if (_reMdPunctuation.hasMatch(next)) {
          text.write(next);
          i += 2;
          continue;
        }
      }
      if (c == "\n") {
        final String pending = text.toString();
        if (pending.endsWith("  ")) {
          text.clear();
          text.write(pending.trimRight());
          add(const UMarkdownInline(UMarkdownInlineKind.lineBreak));
        } else {
          text.clear();
          text.write(pending.trimRight());
          text.write(" ");
        }
        i++;
        while (i < length && source[i] == " ") {
          i++;
        }
        continue;
      }
      if (c == "`") {
        final int run = _run(source, i, "`");
        final int close = _findCodeClose(source, i + run, run);
        if (close >= 0) {
          String code = source.substring(i + run, close).replaceAll("\n", " ");
          if (code.length > 2 && code.startsWith(" ") && code.endsWith(" ") && code.trim().isNotEmpty) code = code.substring(1, code.length - 1);
          add(UMarkdownInline(UMarkdownInlineKind.code, text: code));
          i = close + run;
        } else {
          text.write("`" * run);
          i += run;
        }
        continue;
      }
      if (c == "!" && i + 1 < length && source[i + 1] == "[") {
        final (UMarkdownInline, int)? image = _link(source, i + 1, image: true);
        if (image != null) {
          add(image.$1);
          i = image.$2;
          continue;
        }
      }
      if (c == "[") {
        if (i + 1 < length && source[i + 1] == "^") {
          final int close = source.indexOf("]", i + 2);
          if (close > i + 2) {
            final String label = source.substring(i + 2, close);
            if (tree == null || tree!.footnoteNumber(label) > 0) {
              add(UMarkdownInline(UMarkdownInlineKind.footnote, text: label));
              i = close + 1;
              continue;
            }
          }
        }
        if (links) {
          final (UMarkdownInline, int)? link = _link(source, i);
          if (link != null) {
            add(link.$1);
            i = link.$2;
            continue;
          }
        }
      }
      if (c == "<") {
        final String rest = source.substring(i);
        final RegExpMatch? auto = _reMdAutolink.firstMatch(rest);
        if (auto != null && links) {
          final String href = auto.group(1) ?? "";
          add(UMarkdownInline(UMarkdownInlineKind.link, href: href, children: <UMarkdownInline>[UMarkdownInline(UMarkdownInlineKind.text, text: href)]));
          i += auto.end;
          continue;
        }
        final RegExpMatch? email = _reMdEmail.firstMatch(rest);
        if (email != null && links) {
          final String address = email.group(1) ?? "";
          add(UMarkdownInline(UMarkdownInlineKind.link, href: "mailto:$address", children: <UMarkdownInline>[UMarkdownInline(UMarkdownInlineKind.text, text: address)]));
          i += email.end;
          continue;
        }
        final int consumed = _inlineHtml(source, i, add, links: links);
        if (consumed > 0) {
          i += consumed;
          continue;
        }
      }
      if (c == "*" || c == "_") {
        final int consumed = _emphasis(source, i, c, add, text);
        i += consumed;
        continue;
      }
      if ((c == "~" || c == "=") && i + 1 < length && source[i + 1] == c && !_isSpace(i + 2 < length ? source[i + 2] : null)) {
        final int close = _findClose(source, i + 2, c * 2);
        if (close > i + 2) {
          add(UMarkdownInline(c == "~" ? UMarkdownInlineKind.strike : UMarkdownInlineKind.highlight, children: parse(source.substring(i + 2, close), links: links)));
          i = close + 2;
          continue;
        }
      }
      if (links && (c == "h" || c == "w") && (i == 0 || _isSpace(source[i - 1]) || source[i - 1] == "(") && (source.startsWith("http://", i) || source.startsWith("https://", i) || source.startsWith("www.", i))) {
        final RegExpMatch? url = _reMdBareUrl.firstMatch(source.substring(i));
        if (url != null) {
          final String value = url.group(0) ?? "";
          add(UMarkdownInline(UMarkdownInlineKind.link, href: value.startsWith("www.") ? "http://$value" : value, children: <UMarkdownInline>[UMarkdownInline(UMarkdownInlineKind.text, text: value)]));
          i += value.length;
          continue;
        }
      }
      text.write(c);
      i++;
    }
    flush();
    _depth--;
    return out;
  }

  static int _run(String source, int start, String character) {
    int end = start;
    while (end < source.length && source[end] == character) {
      end++;
    }
    return end - start;
  }

  static int _findCodeClose(String source, int from, int run) {
    int i = from;
    while (i < source.length) {
      final int index = source.indexOf("`", i);
      if (index < 0) return -1;
      final int length = _run(source, index, "`");
      if (length == run) return index;
      i = index + length;
    }
    return -1;
  }

  /// Index of [marker] closing a span that started before [from]; skips code spans and escapes.
  static int _findClose(String source, int from, String marker) {
    int i = from;
    while (i < source.length) {
      final String c = source[i];
      if (c == "\\") {
        i += 2;
        continue;
      }
      if (c == "`") {
        final int run = _run(source, i, "`");
        final int close = _findCodeClose(source, i + run, run);
        i = close < 0 ? i + run : close + run;
        continue;
      }
      if (source.startsWith(marker, i) && i > from && !_isSpace(source[i - 1])) return i;
      i++;
    }
    return -1;
  }

  int _emphasis(String source, int start, String c, void Function(UMarkdownInline inline) add, StringBuffer text) {
    final int run = _run(source, start, c);
    final String? before = start > 0 ? source[start - 1] : null;
    final String? after = start + run < source.length ? source[start + run] : null;
    final bool canOpen = !_isSpace(after) && (c == "*" || !_isWord(before));
    if (!canOpen) {
      text.write(c * run);
      return run;
    }
    for (int size = min(run, 3); size >= 1; size--) {
      final int contentStart = start + run;
      final int close = _findEmphasisClose(source, contentStart, c, size);
      if (close < 0) continue;
      final List<UMarkdownInline> inner = parse(source.substring(contentStart, close));
      UMarkdownInline node;
      if (size == 3) {
        node = UMarkdownInline(UMarkdownInlineKind.strong, children: <UMarkdownInline>[UMarkdownInline(UMarkdownInlineKind.emphasis, children: inner)]);
      } else {
        node = UMarkdownInline(size == 2 ? UMarkdownInlineKind.strong : UMarkdownInlineKind.emphasis, children: inner);
      }
      if (run > size) text.write(c * (run - size));
      add(node);
      final int closeRun = _run(source, close, c);
      if (closeRun > size) text.write(c * (closeRun - size));
      return close + closeRun - start;
    }
    text.write(c * run);
    return run;
  }

  static int _findEmphasisClose(String source, int from, String c, int size) {
    int i = from;
    while (i < source.length) {
      final String character = source[i];
      if (character == "\\") {
        i += 2;
        continue;
      }
      if (character == "`") {
        final int run = _run(source, i, "`");
        final int close = _findCodeClose(source, i + run, run);
        i = close < 0 ? i + run : close + run;
        continue;
      }
      if (character == "[") {
        final int close = _matchBracket(source, i);
        if (close > i) {
          i = close + 1;
          continue;
        }
      }
      if (character == c) {
        final int run = _run(source, i, c);
        final String? after = i + run < source.length ? source[i + run] : null;
        final bool canClose = i > from && !_isSpace(source[i - 1]) && (c == "*" || !_isWord(after));
        if (canClose && (run == size || (run > size && size == min(run, 3)))) return i;
        i += run;
        continue;
      }
      i++;
    }
    return -1;
  }

  static int _matchBracket(String source, int open) {
    int depth = 0;
    int i = open;
    while (i < source.length) {
      final String c = source[i];
      if (c == "\\") {
        i += 2;
        continue;
      }
      if (c == "`") {
        final int run = _run(source, i, "`");
        final int close = _findCodeClose(source, i + run, run);
        i = close < 0 ? i + run : close + run;
        continue;
      }
      if (c == "[") depth++;
      if (c == "]") {
        depth--;
        if (depth == 0) return i;
      }
      i++;
    }
    return -1;
  }

  (UMarkdownInline, int)? _link(String source, int open, {bool image = false}) {
    final int close = _matchBracket(source, open);
    if (close < 0) return null;
    final String label = source.substring(open + 1, close);
    String? href;
    String title = "";
    int end = close + 1;
    if (end < source.length && source[end] == "(") {
      int i = end + 1;
      while (i < source.length && _isSpace(source[i])) {
        i++;
      }
      final StringBuffer destination = StringBuffer();
      if (i < source.length && source[i] == "<") {
        final int stop = source.indexOf(">", i);
        if (stop < 0) return null;
        destination.write(source.substring(i + 1, stop));
        i = stop + 1;
      } else {
        int depth = 0;
        while (i < source.length) {
          final String c = source[i];
          if (c == "\\" && i + 1 < source.length) {
            destination.write(source[i + 1]);
            i += 2;
            continue;
          }
          if (_isSpace(c)) break;
          if (c == "(") depth++;
          if (c == ")") {
            if (depth == 0) break;
            depth--;
          }
          destination.write(c);
          i++;
        }
      }
      while (i < source.length && _isSpace(source[i])) {
        i++;
      }
      if (i < source.length && (source[i] == "\"" || source[i] == "'" || source[i] == "(")) {
        final String quote = source[i] == "(" ? ")" : source[i];
        final int stop = source.indexOf(quote, i + 1);
        if (stop < 0) return null;
        title = source.substring(i + 1, stop);
        i = stop + 1;
        while (i < source.length && _isSpace(source[i])) {
          i++;
        }
      }
      if (i >= source.length || source[i] != ")") return null;
      href = destination.toString();
      end = i + 1;
    } else {
      final Map<String, (String, String)> references = tree?.references ?? const <String, (String, String)>{};
      String key = label;
      if (end < source.length && source[end] == "[") {
        final int stop = source.indexOf("]", end + 1);
        if (stop > end) {
          final String explicit = source.substring(end + 1, stop);
          if (explicit.trim().isNotEmpty) key = explicit;
          end = stop + 1;
        }
      }
      final (String, String)? reference = references[key.trim().toLowerCase().replaceAll(_reMdSpaces, " ")];
      if (reference == null) return null;
      href = reference.$1;
      title = reference.$2;
    }
    if (image) {
      final String alt = parse(label, links: false).map((UMarkdownInline inline) => inline.plainText).join();
      return (UMarkdownInline(UMarkdownInlineKind.image, text: alt, href: href, title: title), end);
    }
    return (UMarkdownInline(UMarkdownInlineKind.link, href: href, title: title, children: parse(label, links: false)), end);
  }

  static const Map<String, UMarkdownInlineKind> _tags = <String, UMarkdownInlineKind>{
    "b": UMarkdownInlineKind.strong,
    "strong": UMarkdownInlineKind.strong,
    "i": UMarkdownInlineKind.emphasis,
    "em": UMarkdownInlineKind.emphasis,
    "s": UMarkdownInlineKind.strike,
    "del": UMarkdownInlineKind.strike,
    "strike": UMarkdownInlineKind.strike,
    "u": UMarkdownInlineKind.underline,
    "ins": UMarkdownInlineKind.underline,
    "mark": UMarkdownInlineKind.highlight,
    "sup": UMarkdownInlineKind.superscript,
    "sub": UMarkdownInlineKind.subscript,
    "kbd": UMarkdownInlineKind.keyboard,
    "code": UMarkdownInlineKind.code,
    "a": UMarkdownInlineKind.link,
  };

  static Map<String, String> _attributes(String source) {
    final Map<String, String> out = <String, String>{};
    for (final RegExpMatch match in _reMdAttribute.allMatches(source)) {
      out[(match.group(1) ?? "").toLowerCase()] = UEpubXml.decodeEntities(match.group(2) ?? match.group(3) ?? match.group(4) ?? "");
    }
    return out;
  }

  int _inlineHtml(String source, int start, void Function(UMarkdownInline inline) add, {required bool links}) {
    final RegExpMatch? match = _reMdInlineTag.firstMatch(source.substring(start));
    if (match == null) return 0;
    final String name = (match.group(2) ?? "").toLowerCase();
    final bool closing = (match.group(1) ?? "").isNotEmpty;
    final Map<String, String> attributes = _attributes(match.group(3) ?? "");
    if (closing) return match.end;
    if (name == "br") {
      add(const UMarkdownInline(UMarkdownInlineKind.lineBreak));
      return match.end;
    }
    if (name == "img") {
      add(UMarkdownInline(UMarkdownInlineKind.image, href: attributes["src"] ?? "", text: attributes["alt"] ?? "", title: attributes["title"] ?? ""));
      return match.end;
    }
    final UMarkdownInlineKind? kind = _tags[name];
    if (kind == null || (match.group(4) ?? "").isNotEmpty) return match.end;
    final int contentStart = start + match.end;
    final int close = source.toLowerCase().indexOf("</$name>", contentStart);
    if (close < 0) return match.end;
    final String inner = source.substring(contentStart, close);
    final int consumed = close + name.length + 3 - start;
    if (kind == UMarkdownInlineKind.code) {
      add(UMarkdownInline(UMarkdownInlineKind.code, text: UEpubXml.decodeEntities(inner)));
    } else if (kind == UMarkdownInlineKind.link) {
      final String href = attributes["href"] ?? "";
      if (href.isEmpty || !links) {
        for (final UMarkdownInline child in parse(inner, links: links)) {
          add(child);
        }
      } else {
        add(UMarkdownInline(UMarkdownInlineKind.link, href: href, title: attributes["title"] ?? "", children: parse(inner, links: false)));
      }
    } else {
      add(UMarkdownInline(kind, children: parse(inner, links: links)));
    }
    return consumed;
  }
}

/// Inline style while flattening inlines into reader spans.
class _UMarkdownStyle {
  const _UMarkdownStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.monospace = false,
    this.superscript = false,
    this.subscript = false,
    this.background,
    this.href,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool monospace;
  final bool superscript;
  final bool subscript;
  final Color? background;
  final String? href;

  _UMarkdownStyle copyWith({bool? bold, bool? italic, bool? underline, bool? strike, bool? monospace, bool? superscript, bool? subscript, Color? background, String? href}) => _UMarkdownStyle(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    strike: strike ?? this.strike,
    monospace: monospace ?? this.monospace,
    superscript: superscript ?? this.superscript,
    subscript: subscript ?? this.subscript,
    background: background ?? this.background,
    href: href ?? this.href,
  );

  UEpubSpan span(String text, {Color? color}) => UEpubSpan(
    text: text,
    bold: bold,
    italic: italic,
    underline: underline,
    strike: strike,
    monospace: monospace,
    superscript: superscript,
    subscript: subscript,
    background: background,
    href: href,
    color: color,
  );
}

/// An image met while flattening a paragraph.
class _UMarkdownImage {
  const _UMarkdownImage(this.href);

  final String href;
}

class _UMarkdownBlockBuilder {
  _UMarkdownBlockBuilder(this.tree);

  final UMarkdownTree tree;
  final List<UEpubBlock> blocks = <UEpubBlock>[];
  final List<(int, int, String, String)> headings = <(int, int, String, String)>[];

  static const Color _codeBackground = Color(0x1F808080);
  static const Color _markBackground = Color(0x66FFEB3B);
  static const List<String> _bullets = <String>["•", "◦", "▪"];

  UMarkdownLayout layout(int chapterLevel) {
    build(tree.blocks);
    if (tree.footnotes.isNotEmpty) {
      blocks.add(const UEpubBlock(kind: UEpubBlockKind.rule, marginTop: 12));
      for (int i = 0; i < tree.footnotes.length; i++) {
        final UMarkdownNode footnote = tree.footnotes[i];
        final int first = blocks.length;
        _items(footnote.children, 0, 0, 0, marker: "${i + 1}.");
        if (blocks.length > first) {
          final UEpubBlock head = blocks[first];
          blocks[first] = UEpubBlock(kind: head.kind, spans: head.spans, level: head.level, indent: head.indent, marginTop: head.marginTop, marginBottom: head.marginBottom, listMarker: head.listMarker, anchorId: "fn-${footnote.id}", rtl: head.rtl);
        }
      }
    }
    final String title = tree.frontMatter["title"] ?? headings.where(((int, int, String, String) heading) => heading.$2 == 1).map(((int, int, String, String) heading) => heading.$3).firstOrNull ?? "";
    final List<int> starts = <int>[0];
    if (chapterLevel > 0) {
      for (final (int, int, String, String) heading in headings) {
        if (heading.$2 <= chapterLevel && heading.$1 > starts.last) starts.add(heading.$1);
      }
    }
    final List<UEpubChapter> chapters = <UEpubChapter>[];
    final Map<String, int> anchors = <String, int>{};
    int chapterOf(int block) {
      int index = 0;
      for (int i = 0; i < starts.length; i++) {
        if (starts[i] <= block) index = i;
      }
      return index;
    }

    for (int i = 0; i < starts.length; i++) {
      final int end = i + 1 < starts.length ? starts[i + 1] : blocks.length;
      final List<UEpubBlock> part = blocks.sublist(starts[i], end);
      for (final UEpubBlock block in part) {
        final String? anchor = block.anchorId;
        if (anchor != null) anchors[anchor] = i;
      }
      final String chapterTitle = headings.where(((int, int, String, String) heading) => heading.$1 >= starts[i] && heading.$1 < end).map(((int, int, String, String) heading) => heading.$3).firstOrNull ?? title;
      chapters.add(
        UEpubChapter(
          spineIndex: i,
          href: "md-$i",
          blocks: part,
          title: chapterTitle,
          text: part.where((UEpubBlock block) => block.isText).map((UEpubBlock block) => block.text).join("\n"),
        ),
      );
    }
    final List<UDocOutlineNode> outline = _outline(chapterOf);
    final String sample = chapters.isEmpty ? "" : chapters.first.text;
    final String language = (tree.frontMatter["lang"] ?? tree.frontMatter["language"] ?? "").toLowerCase();
    final String dir = (tree.frontMatter["dir"] ?? "").toLowerCase();
    final bool rtl = dir == "rtl" ||
        (dir != "ltr" &&
            (language.startsWith("fa") || language.startsWith("ar") || language.startsWith("he") || language.startsWith("ur") || UDocText.isMostlyRtl(sample.length > 4000 ? sample.substring(0, 4000) : sample)));
    return UMarkdownLayout(
      chapters: chapters,
      outline: outline,
      anchors: anchors,
      direction: rtl ? UDocDirection.rtl : UDocDirection.ltr,
      metadata: UDocMetadata(
        title: title.isEmpty ? null : title,
        author: tree.frontMatter["author"],
        subject: tree.frontMatter["description"] ?? tree.frontMatter["subject"],
        keywords: tree.frontMatter["keywords"] ?? tree.frontMatter["tags"],
        language: language.isEmpty ? null : language,
        pageCount: chapters.length,
        custom: tree.frontMatter,
      ),
    );
  }

  List<UDocOutlineNode> _outline(int Function(int block) chapterOf) {
    final List<(int, UDocOutlineNode, List<UDocOutlineNode>)> stack = <(int, UDocOutlineNode, List<UDocOutlineNode>)>[];
    final List<UDocOutlineNode> roots = <UDocOutlineNode>[];
    UDocOutlineNode freeze((int, UDocOutlineNode, List<UDocOutlineNode>) entry) =>
        UDocOutlineNode(title: entry.$2.title, destination: entry.$2.destination, children: List<UDocOutlineNode>.unmodifiable(entry.$3), expanded: true);
    void pop() {
      final (int, UDocOutlineNode, List<UDocOutlineNode>) done = stack.removeLast();
      final UDocOutlineNode node = freeze(done);
      if (stack.isEmpty) {
        roots.add(node);
      } else {
        stack.last.$3.add(node);
      }
    }

    for (final (int, int, String, String) heading in headings) {
      while (stack.isNotEmpty && stack.last.$1 >= heading.$2) {
        pop();
      }
      stack.add((heading.$2, UDocOutlineNode(title: heading.$3, destination: UDocDestination(pageIndex: chapterOf(heading.$1), anchor: heading.$4)), <UDocOutlineNode>[]));
    }
    while (stack.isNotEmpty) {
      pop();
    }
    return roots;
  }

  void build(List<UMarkdownNode> nodes, {double indent = 0, int quote = 0, int list = 0}) {
    for (final UMarkdownNode node in nodes) {
      switch (node.kind) {
        case UMarkdownBlockKind.heading:
          final List<Object> parts = _flatten(UMarkdown.parseInline(node.text, tree: tree));
          final List<UEpubSpan> spans = parts.whereType<UEpubSpan>().toList();
          final String text = spans.map((UEpubSpan span) => span.text).join();
          headings.add((blocks.length, node.level, text.trim(), node.id));
          blocks.add(
            UEpubBlock(
              kind: UEpubBlockKind.heading,
              spans: spans.isEmpty ? const <UEpubSpan>[UEpubSpan(text: " ")] : spans,
              level: node.level,
              indent: indent,
              anchorId: node.id,
              marginTop: node.level <= 2 ? 20 : 14,
              marginBottom: node.level <= 2 ? 8 : 4,
            ),
          );
          if (node.level <= 2 && quote == 0 && list == 0) blocks.add(const UEpubBlock(kind: UEpubBlockKind.rule));
        case UMarkdownBlockKind.paragraph:
          _paragraph(node.text, quote > 0 ? UEpubBlockKind.blockquote : UEpubBlockKind.paragraph, indent);
        case UMarkdownBlockKind.code:
          blocks.add(UEpubBlock(kind: UEpubBlockKind.preformatted, spans: _highlight(node.text, node.info), indent: indent, marginTop: 4, marginBottom: 8, align: TextAlign.left));
        case UMarkdownBlockKind.quote:
          build(node.children, indent: indent + (quote > 0 ? 16 : 0), quote: quote + 1, list: list);
        case UMarkdownBlockKind.list:
          for (int i = 0; i < node.children.length; i++) {
            final UMarkdownNode item = node.children[i];
            final String marker = item.checked != null ? (item.checked! ? "☑" : "☐") : (node.ordered ? "${node.start + i}." : _bullets[list % _bullets.length]);
            _items(item.children, indent, quote, list, marker: marker);
          }
        case UMarkdownBlockKind.item:
          _items(node.children, indent, quote, list, marker: _bullets[list % _bullets.length]);
        case UMarkdownBlockKind.table:
          for (int r = 0; r < node.rows.length; r++) {
            blocks.add(
              UEpubBlock(
                kind: UEpubBlockKind.tableRow,
                level: r == 0 ? 1 : 0,
                indent: indent,
                marginTop: r == 0 ? 6 : 0,
                marginBottom: r == node.rows.length - 1 ? 8 : 0,
                cells: node.rows[r]
                    .map((String cell) => _flatten(UMarkdown.parseInline(cell, tree: tree), _UMarkdownStyle(bold: r == 0)).whereType<UEpubSpan>().toList())
                    .toList(),
              ),
            );
          }
        case UMarkdownBlockKind.rule:
          blocks.add(UEpubBlock(kind: UEpubBlockKind.rule, indent: indent, marginTop: 8));
        case UMarkdownBlockKind.html:
          if (quote + list < 8) build(UMarkdown.parse(UMarkdown.fromHtml(node.text)).blocks, indent: indent, quote: quote, list: list + 4);
        case UMarkdownBlockKind.footnote:
          build(node.children, indent: indent, quote: quote, list: list);
      }
    }
  }

  void _items(List<UMarkdownNode> children, double indent, int quote, int list, {required String marker}) {
    final List<UMarkdownNode> rest = List<UMarkdownNode>.from(children);
    List<UEpubSpan> spans = const <UEpubSpan>[UEpubSpan(text: " ")];
    final List<String> images = <String>[];
    if (rest.isNotEmpty && rest.first.kind == UMarkdownBlockKind.paragraph) {
      final List<Object> parts = _flatten(UMarkdown.parseInline(rest.removeAt(0).text, tree: tree));
      final List<UEpubSpan> text = parts.whereType<UEpubSpan>().toList();
      if (text.isNotEmpty) spans = text;
      images.addAll(parts.whereType<_UMarkdownImage>().map((_UMarkdownImage image) => image.href));
    }
    blocks.add(UEpubBlock(kind: UEpubBlockKind.listItem, spans: spans, listMarker: marker, indent: indent, marginBottom: 2));
    for (final String href in images) {
      blocks.add(UEpubBlock(kind: UEpubBlockKind.image, imageHref: href, indent: indent + 32, marginTop: 4));
    }
    build(rest, indent: indent + 32, quote: quote, list: list + 1);
  }

  void _paragraph(String text, UEpubBlockKind kind, double indent) {
    final List<Object> parts = _flatten(UMarkdown.parseInline(text, tree: tree));
    List<UEpubSpan> pending = <UEpubSpan>[];
    void flush() {
      final String joined = pending.map((UEpubSpan span) => span.text).join();
      if (joined.trim().isNotEmpty) {
        while (pending.isNotEmpty && pending.first.text.trim().isEmpty) {
          pending.removeAt(0);
        }
        blocks.add(UEpubBlock(kind: kind, spans: pending, indent: indent, marginBottom: 4));
      }
      pending = <UEpubSpan>[];
    }

    for (final Object part in parts) {
      if (part is UEpubSpan) {
        pending.add(part);
      } else if (part is _UMarkdownImage) {
        flush();
        blocks.add(UEpubBlock(kind: UEpubBlockKind.image, imageHref: part.href, indent: indent, marginTop: 4));
      }
    }
    flush();
  }

  List<Object> _flatten(List<UMarkdownInline> inlines, [_UMarkdownStyle style = const _UMarkdownStyle()]) {
    final List<Object> out = <Object>[];
    void walk(List<UMarkdownInline> nodes, _UMarkdownStyle current) {
      for (final UMarkdownInline node in nodes) {
        switch (node.kind) {
          case UMarkdownInlineKind.text:
            if (node.text.isNotEmpty) out.add(current.span(node.text));
          case UMarkdownInlineKind.code:
            out.add(current.copyWith(monospace: true, background: _codeBackground).span(node.text));
          case UMarkdownInlineKind.keyboard:
            walk(node.children, current.copyWith(monospace: true, background: _codeBackground));
          case UMarkdownInlineKind.emphasis:
            walk(node.children, current.copyWith(italic: true));
          case UMarkdownInlineKind.strong:
            walk(node.children, current.copyWith(bold: true));
          case UMarkdownInlineKind.strike:
            walk(node.children, current.copyWith(strike: true));
          case UMarkdownInlineKind.underline:
            walk(node.children, current.copyWith(underline: true));
          case UMarkdownInlineKind.highlight:
            walk(node.children, current.copyWith(background: _markBackground));
          case UMarkdownInlineKind.superscript:
            walk(node.children, current.copyWith(superscript: true));
          case UMarkdownInlineKind.subscript:
            walk(node.children, current.copyWith(subscript: true));
          case UMarkdownInlineKind.link:
            walk(node.children, current.copyWith(href: node.href));
          case UMarkdownInlineKind.image:
            if (node.href.isNotEmpty) out.add(_UMarkdownImage(node.href));
          case UMarkdownInlineKind.lineBreak:
            out.add(current.span("\n"));
          case UMarkdownInlineKind.footnote:
            final int number = tree.footnoteNumber(node.text);
            if (number > 0) out.add(current.copyWith(superscript: true, href: "#fn-${node.text}").span("[$number]"));
        }
      }
    }

    walk(inlines, style);
    return out;
  }

  static const Set<String> _keywords = <String>{
    "abstract", "and", "as", "async", "await", "break", "case", "catch", "class", "const", "continue", "def", "default", "defer", "del", "do", "elif", "else", "enum",
    "except", "export", "extends", "false", "final", "finally", "fn", "for", "from", "func", "function", "go", "if", "implements", "import", "in", "interface", "is",
    "lambda", "late", "let", "match", "mixin", "mut", "namespace", "new", "nil", "None", "not", "null", "or", "override", "package", "pass", "private", "protected",
    "pub", "public", "raise", "required", "return", "self", "static", "struct", "super", "switch", "this", "throw", "throws", "trait", "True", "False", "true", "try",
    "type", "typeof", "use", "using", "val", "var", "void", "when", "where", "while", "with", "yield", "int", "double", "string", "String", "bool", "select", "SELECT",
    "FROM", "WHERE", "INSERT", "UPDATE", "DELETE", "JOIN", "ORDER", "GROUP", "BY", "CREATE", "TABLE", "echo", "then", "fi", "esac", "done", "end", "elsif", "begin",
  };

  static List<UEpubSpan> _highlight(String code, String language) {
    if (code.isEmpty) return const <UEpubSpan>[UEpubSpan(text: " ", monospace: true)];
    if (code.length > 60000 || <String>{"text", "txt", "plain", "plaintext", "md", "markdown"}.contains(language)) return <UEpubSpan>[UEpubSpan(text: code, monospace: true)];
    const Color keyword = Color(0xFF7C4DFF);
    const Color string = Color(0xFF2E7D32);
    const Color comment = Color(0xFF8A8A8A);
    const Color number = Color(0xFFD84315);
    final bool hash = <String>{"python", "py", "ruby", "rb", "sh", "bash", "zsh", "shell", "yaml", "yml", "toml", "r", "perl", "dockerfile", "makefile", "ini", "conf", "powershell", "ps1"}.contains(language);
    final bool dash = <String>{"sql", "lua", "haskell", "hs"}.contains(language);
    final List<(int, int, Color)> marks = <(int, int, Color)>[];
    if (hash || dash) {
      for (final RegExpMatch match in (hash ? _reMdHashComment : _reMdDashComment).allMatches(code)) {
        marks.add((match.start, match.end, comment));
      }
    }
    bool covered(int index) => marks.any(((int, int, Color) mark) => index >= mark.$1 && index < mark.$2);
    for (final RegExpMatch match in _reMdCode.allMatches(code)) {
      if (covered(match.start)) continue;
      if (match.group(1) != null) {
        marks.add((match.start, match.end, comment));
      } else if (match.group(2) != null) {
        marks.add((match.start, match.end, string));
      } else if (match.group(3) != null) {
        marks.add((match.start, match.end, number));
      } else if (_keywords.contains(match.group(4))) {
        marks.add((match.start, match.end, keyword));
      }
    }
    marks.sort(((int, int, Color) a, (int, int, Color) b) => a.$1.compareTo(b.$1));
    final List<UEpubSpan> spans = <UEpubSpan>[];
    int cursor = 0;
    for (final (int, int, Color) mark in marks) {
      if (mark.$1 < cursor) continue;
      if (mark.$1 > cursor) spans.add(UEpubSpan(text: code.substring(cursor, mark.$1), monospace: true));
      spans.add(UEpubSpan(text: code.substring(mark.$1, mark.$2), monospace: true, color: mark.$3));
      cursor = mark.$2;
    }
    if (cursor < code.length) spans.add(UEpubSpan(text: code.substring(cursor), monospace: true));
    return spans;
  }
}

class _UMarkdownHtml {
  _UMarkdownHtml(this.tree);

  final UMarkdownTree tree;
  final StringBuffer _out = StringBuffer();

  String render() {
    _blocks(tree.blocks);
    if (tree.footnotes.isNotEmpty) {
      _out.writeln("<hr>\n<ol class=\"footnotes\">");
      for (final UMarkdownNode footnote in tree.footnotes) {
        _out.write("<li id=\"fn-${_attr(footnote.id)}\">");
        _blocks(footnote.children, tight: true);
        _out.writeln("</li>");
      }
      _out.writeln("</ol>");
    }
    return _out.toString().trim();
  }

  static String _text(String value) => value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

  static String _attr(String value) => _text(value).replaceAll("\"", "&quot;");

  static String _align(TextAlign? align) {
    switch (align) {
      case TextAlign.center:
        return " style=\"text-align:center\"";
      case TextAlign.end:
      case TextAlign.right:
        return " style=\"text-align:right\"";
      case TextAlign.start:
      case TextAlign.left:
        return " style=\"text-align:left\"";
      default:
        return "";
    }
  }

  void _blocks(List<UMarkdownNode> nodes, {bool tight = false}) {
    for (final UMarkdownNode node in nodes) {
      switch (node.kind) {
        case UMarkdownBlockKind.heading:
          _out.writeln("<h${node.level} id=\"${_attr(node.id)}\">${_inline(UMarkdown.parseInline(node.text, tree: tree))}</h${node.level}>");
        case UMarkdownBlockKind.paragraph:
          final String content = _inline(UMarkdown.parseInline(node.text, tree: tree));
          _out.writeln(tight ? content : "<p>$content</p>");
        case UMarkdownBlockKind.code:
          _out.writeln("<pre><code${node.info.isEmpty ? "" : " class=\"language-${_attr(node.info)}\""}>${_text(node.text)}</code></pre>");
        case UMarkdownBlockKind.quote:
          _out.writeln("<blockquote>");
          _blocks(node.children);
          _out.writeln("</blockquote>");
        case UMarkdownBlockKind.list:
          final String tag = node.ordered ? "ol" : "ul";
          _out.writeln(node.ordered && node.start != 1 ? "<ol start=\"${node.start}\">" : "<$tag>");
          for (final UMarkdownNode item in node.children) {
            final bool? checked = item.checked;
            _out.write(checked == null ? "<li>" : "<li class=\"task\"><input type=\"checkbox\" disabled${checked ? " checked" : ""}> ");
            _blocks(item.children, tight: item.children.length <= 1 || item.children.every((UMarkdownNode child) => child.kind != UMarkdownBlockKind.paragraph || child == item.children.first));
            _out.writeln("</li>");
          }
          _out.writeln("</$tag>");
        case UMarkdownBlockKind.item:
          _blocks(node.children, tight: true);
        case UMarkdownBlockKind.table:
          _out.writeln("<table>");
          for (int r = 0; r < node.rows.length; r++) {
            if (r == 0) _out.writeln("<thead>");
            if (r == 1) _out.writeln("<tbody>");
            _out.write("<tr>");
            for (int c = 0; c < node.rows[r].length; c++) {
              final String cell = r == 0 ? "th" : "td";
              _out.write("<$cell${_align(c < node.aligns.length ? node.aligns[c] : null)}>${_inline(UMarkdown.parseInline(node.rows[r][c], tree: tree))}</$cell>");
            }
            _out.writeln("</tr>");
            if (r == 0) _out.writeln("</thead>");
          }
          if (node.rows.length > 1) _out.writeln("</tbody>");
          _out.writeln("</table>");
        case UMarkdownBlockKind.rule:
          _out.writeln("<hr>");
        case UMarkdownBlockKind.html:
          _out.writeln(node.text);
        case UMarkdownBlockKind.footnote:
          _blocks(node.children);
      }
    }
  }

  String _inline(List<UMarkdownInline> nodes) {
    final StringBuffer buffer = StringBuffer();
    for (final UMarkdownInline node in nodes) {
      switch (node.kind) {
        case UMarkdownInlineKind.text:
          buffer.write(_text(node.text));
        case UMarkdownInlineKind.code:
          buffer.write("<code>${_text(node.text)}</code>");
        case UMarkdownInlineKind.emphasis:
          buffer.write("<em>${_inline(node.children)}</em>");
        case UMarkdownInlineKind.strong:
          buffer.write("<strong>${_inline(node.children)}</strong>");
        case UMarkdownInlineKind.strike:
          buffer.write("<del>${_inline(node.children)}</del>");
        case UMarkdownInlineKind.highlight:
          buffer.write("<mark>${_inline(node.children)}</mark>");
        case UMarkdownInlineKind.underline:
          buffer.write("<u>${_inline(node.children)}</u>");
        case UMarkdownInlineKind.superscript:
          buffer.write("<sup>${_inline(node.children)}</sup>");
        case UMarkdownInlineKind.subscript:
          buffer.write("<sub>${_inline(node.children)}</sub>");
        case UMarkdownInlineKind.keyboard:
          buffer.write("<kbd>${_inline(node.children)}</kbd>");
        case UMarkdownInlineKind.link:
          buffer.write("<a href=\"${_attr(node.href)}\"${node.title.isEmpty ? "" : " title=\"${_attr(node.title)}\""}>${_inline(node.children)}</a>");
        case UMarkdownInlineKind.image:
          buffer.write("<img src=\"${_attr(node.href)}\" alt=\"${_attr(node.text)}\"${node.title.isEmpty ? "" : " title=\"${_attr(node.title)}\""}>");
        case UMarkdownInlineKind.lineBreak:
          buffer.write("<br>\n");
        case UMarkdownInlineKind.footnote:
          final int number = tree.footnoteNumber(node.text);
          buffer.write("<sup><a href=\"#fn-${_attr(node.text)}\">$number</a></sup>");
      }
    }
    return buffer.toString();
  }
}

class _UMarkdownFromHtml {
  static const Set<String> _blockTags = <String>{
    "p", "div", "section", "article", "header", "footer", "main", "aside", "nav", "figure", "figcaption", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "li",
    "blockquote", "pre", "table", "thead", "tbody", "tfoot", "tr", "hr", "details", "summary", "dl", "dt", "dd", "center",
  };

  static String _escape(String text) => text.replaceAllMapped(RegExp(r"([\\`*_\[\]])"), (Match match) => "\\${match.group(1)}");

  String blocks(List<UEpubNode> nodes, int depth) {
    final StringBuffer out = StringBuffer();
    final List<UEpubNode> inline = <UEpubNode>[];
    void flushInline() {
      final String text = inlines(inline).trim();
      inline.clear();
      if (text.isNotEmpty) out.write("$text\n\n");
    }

    for (final UEpubNode node in nodes) {
      if (node.isText || !_blockTags.contains(node.tag)) {
        if (node.tag == "script" || node.tag == "style" || node.tag == "head" || node.tag == "title") continue;
        inline.add(node);
        continue;
      }
      flushInline();
      out.write(block(node, depth));
    }
    flushInline();
    return out.toString();
  }

  String block(UEpubNode node, int depth) {
    if (depth > 30) return "";
    switch (node.tag) {
      case "h1":
      case "h2":
      case "h3":
      case "h4":
      case "h5":
      case "h6":
        final String id = node.id.isEmpty ? "" : " {#${node.id}}";
        return "${"#" * int.parse(node.tag.substring(1))} ${inlines(node.children).trim().replaceAll("\n", " ")}$id\n\n";
      case "hr":
        return "---\n\n";
      case "pre":
        String language = "";
        for (final UEpubNode code in node.findAll("code")) {
          for (final String name in code.classes) {
            if (name.startsWith("language-")) language = name.substring(9);
          }
        }
        final String code = node.textContent.replaceAll(RegExp(r"^\n|\n$"), "");
        final String fence = code.contains("```") ? "~~~" : "```";
        return "$fence$language\n$code\n$fence\n\n";
      case "blockquote":
        final String inner = blocks(node.children, depth + 1).trim();
        return "${inner.split("\n").map((String line) => line.isEmpty ? ">" : "> $line").join("\n")}\n\n";
      case "ul":
      case "ol":
        return "${_list(node, depth)}\n";
      case "table":
        return _table(node);
      default:
        return blocks(node.children, depth + 1);
    }
  }

  String _list(UEpubNode node, int depth) {
    final bool ordered = node.tag == "ol";
    int number = int.tryParse(node.attributes["start"] ?? "") ?? 1;
    final StringBuffer out = StringBuffer();
    for (final UEpubNode item in node.children.where((UEpubNode child) => child.tag == "li")) {
      String prefix = ordered ? "$number. " : "- ";
      number++;
      for (final UEpubNode input in item.findAll("input")) {
        if ((input.attributes["type"] ?? "") == "checkbox") prefix += input.attributes.containsKey("checked") ? "[x] " : "[ ] ";
        break;
      }
      final String body = blocks(item.children, depth + 1).trim();
      final List<String> lines = body.split("\n");
      final String pad = " " * (ordered ? prefix.length.clamp(3, 4) : 2);
      out.write("$prefix${lines.first}\n");
      for (final String line in lines.skip(1)) {
        out.write(line.isEmpty ? "\n" : "$pad$line\n");
      }
    }
    return out.toString();
  }

  String _table(UEpubNode node) {
    final List<List<String>> rows = <List<String>>[];
    final List<String> aligns = <String>[];
    for (final UEpubNode row in node.findAll("tr")) {
      if (aligns.isEmpty) {
        for (final UEpubNode cell in row.children.where((UEpubNode cell) => cell.tag == "td" || cell.tag == "th")) {
          final String style = "${cell.attributes["style"] ?? ""} ${cell.attributes["align"] ?? ""}".toLowerCase();
          aligns.add(style.contains("center") ? " :---: " : (style.contains("right") ? " ---: " : (style.contains("left") ? " :--- " : " --- ")));
        }
      }
      rows.add(row.children.where((UEpubNode cell) => cell.tag == "td" || cell.tag == "th").map((UEpubNode cell) => inlines(cell.children).trim().replaceAll("\n", " ").replaceAll("|", "\\|")).toList());
    }
    if (rows.isEmpty) return "";
    final int columns = rows.fold(0, (int value, List<String> row) => max(value, row.length));
    String line(List<String> cells) => "| ${<String>[...cells, ...List<String>.filled(columns - cells.length, "")].join(" | ")} |";
    final StringBuffer out = StringBuffer();
    out.writeln(line(rows.first));
    out.writeln("|${List<String>.generate(columns, (int index) => index < aligns.length ? aligns[index] : " --- ").join("|")}|");
    for (final List<String> row in rows.skip(1)) {
      out.writeln(line(row));
    }
    return "$out\n";
  }

  String inlines(List<UEpubNode> nodes) {
    final StringBuffer out = StringBuffer();
    for (final UEpubNode node in nodes) {
      out.write(inline(node));
    }
    return out.toString();
  }

  String _wrap(String marker, UEpubNode node) {
    final String inner = inlines(node.children);
    final String trimmed = inner.trim();
    if (trimmed.isEmpty) return inner;
    final String lead = inner.startsWith(" ") ? " " : "";
    final String tail = inner.endsWith(" ") ? " " : "";
    return "$lead$marker$trimmed$marker$tail";
  }

  String inline(UEpubNode node) {
    if (node.isText) {
      final bool pre = _inPre(node);
      return pre ? node.text : _escape(node.text.replaceAll(_reMdSpaces, " "));
    }
    switch (node.tag) {
      case "br":
        return "  \n";
      case "b":
      case "strong":
        return _wrap("**", node);
      case "i":
      case "em":
        return _wrap("*", node);
      case "s":
      case "del":
      case "strike":
        return _wrap("~~", node);
      case "mark":
        return _wrap("==", node);
      case "u":
      case "ins":
      case "sup":
      case "sub":
      case "kbd":
        return "<${node.tag}>${inlines(node.children)}</${node.tag}>";
      case "code":
        final String code = node.textContent;
        final String ticks = code.contains("`") ? "``" : "`";
        return "$ticks$code$ticks";
      case "a":
        final String href = node.attributes["href"] ?? "";
        final String title = node.attributes["title"] ?? "";
        final String label = inlines(node.children).trim();
        if (href.isEmpty) return label;
        return "[$label](${href.replaceAll(" ", "%20")}${title.isEmpty ? "" : " \"$title\""})";
      case "img":
        final String alt = node.attributes["alt"] ?? "";
        return "![$alt](${(node.attributes["src"] ?? "").replaceAll(" ", "%20")})";
      case "input":
        return "";
      case "script":
      case "style":
        return "";
      default:
        if (_blockTags.contains(node.tag)) return "\n\n${block(node, 1).trim()}\n\n";
        return inlines(node.children);
    }
  }

  static bool _inPre(UEpubNode node) {
    UEpubNode? parent = node.parent;
    while (parent != null) {
      if (parent.tag == "pre") return true;
      parent = parent.parent;
    }
    return false;
  }
}

/// A Markdown document as content of the reflowable reader (see [UEpubReader]).
class UMarkdownDocument extends UEpubSource {
  UMarkdownDocument._(this.markdown, this.fingerprint, this._layout, {this.basePath, this.baseUrl, this.headers, this.resourceLoader});

  /// Lays out [markdown]. [basePath] / [baseUrl] / asset folder resolve relative image paths.
  static Future<UMarkdownDocument> create(
    String markdown, {
    required String fingerprint,
    int chapterLevel = 0,
    String? basePath,
    String? baseUrl,
    Map<String, String>? headers,
    Future<Uint8List?> Function(String href)? resourceLoader,
  }) async {
    final UMarkdownLayout layout = markdown.length > 120000 && !kIsWeb ? await compute(_buildLayout, (markdown, chapterLevel)) : _buildLayout((markdown, chapterLevel));
    return UMarkdownDocument._(markdown, fingerprint, layout, basePath: basePath, baseUrl: baseUrl, headers: headers, resourceLoader: resourceLoader);
  }

  static UMarkdownLayout _buildLayout((String, int) input) => UMarkdown.layout(input.$1, chapterLevel: input.$2);

  /// Source text.
  final String markdown;

  @override
  final String fingerprint;

  final UMarkdownLayout _layout;

  /// Folder of the file (or asset) relative images are read from.
  final String? basePath;

  /// Web address relative images are resolved against.
  final String? baseUrl;

  /// HTTP headers for remote images.
  final Map<String, String>? headers;

  /// Loads images yourself (e.g. from a vault); return null to fall back to the default loading.
  final Future<Uint8List?> Function(String href)? resourceLoader;

  UMarkdownLayout get layout => _layout;

  @override
  int get chapterCount => _layout.chapters.length;

  @override
  UDocMetadata get metadata => _layout.metadata;

  @override
  UDocDirection get direction => _layout.direction;

  @override
  List<UDocOutlineNode> get navigation => _layout.outline;

  @override
  Future<UEpubChapter> chapter(int index) async {
    if (index < 0 || index >= _layout.chapters.length) return UEpubChapter(spineIndex: index, href: "", blocks: const <UEpubBlock>[], title: "", text: "");
    return _layout.chapters[index];
  }

  @override
  int spineIndexFor(String href) {
    final int hash = href.indexOf("#");
    if (hash >= 0) {
      final int? chapter = _layout.anchors[Uri.decodeComponent(href.substring(hash + 1))];
      if (chapter != null) return chapter;
    }
    final String base = hash < 0 ? href : href.substring(0, hash);
    if (base.startsWith("md-")) return int.tryParse(base.substring(3)) ?? -1;
    return -1;
  }

  @override
  Future<Uint8List> resource(String href) async {
    try {
      final Future<Uint8List?> Function(String href)? loader = resourceLoader;
      if (loader != null) {
        final Uint8List? custom = await loader(href);
        if (custom != null) return custom;
      }
      if (href.startsWith("data:")) return UriData.parse(href).contentAsBytes();
      final Uri? uri = Uri.tryParse(href);
      if (uri == null) return Uint8List(0);
      if (uri.hasScheme && (uri.scheme == "http" || uri.scheme == "https")) return await _download(uri);
      final String? web = baseUrl;
      if (web != null && !uri.hasScheme) return await _download(Uri.parse(web).resolveUri(uri));
      final String path = Uri.decodeFull(uri.path);
      final String? folder = basePath;
      if (folder != null && folder.startsWith("asset:")) {
        final ByteData data = await rootBundle.load(_join(folder.substring(6), path));
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }
      if (kIsWeb) return Uint8List(0);
      final File file = File(path.startsWith("/") || folder == null ? path : _join(folder, path));
      return file.existsSync() ? await file.readAsBytes() : Uint8List(0);
    } on Object {
      return Uint8List(0);
    }
  }

  static String _join(String folder, String path) {
    final List<String> parts = folder.split("/").where((String part) => part.isNotEmpty).toList();
    for (final String part in path.split("/")) {
      if (part == "..") {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part.isNotEmpty && part != ".") {
        parts.add(part);
      }
    }
    return "${folder.startsWith("/") ? "/" : ""}${parts.join("/")}";
  }

  Future<Uint8List> _download(Uri uri) async {
    final Response response = await get(uri, headers: headers).timeout(const Duration(seconds: 30));
    return response.statusCode >= 200 && response.statusCode < 300 ? response.bodyBytes : Uint8List(0);
  }

  @override
  Future<void> close() async {}
}

/// Controls a Markdown reader/editor: open, edit, export and save. All reader features of [UEpubController] work on it.
class UMarkdownController extends UEpubController {
  UMarkdownController({this.chapterLevel = 0});

  /// New chapter at every heading of this level or higher (0 = one chapter).
  final int chapterLevel;

  String _text = "";
  String _saved = "";
  String _fingerprint = "markdown";
  String? _basePath;
  String? _baseUrl;
  Map<String, String>? _headers;
  Future<Uint8List?> Function(String href)? _resourceLoader;
  int _editToken = 0;

  /// Current Markdown text.
  String get text => _text;

  /// The text was changed since it was opened or last marked saved.
  bool get isDirty => _text != _saved;

  /// The open Markdown document.
  UMarkdownDocument? get document {
    final UEpubSource? current = source;
    return current is UMarkdownDocument ? current : null;
  }

  /// Opens Markdown from text, bytes, a file, an asset, a URL or the encrypted vault ([storageKey]).
  /// [documentId] keeps progress and annotations under a stable id (defaults to the source's path/url/key, or the content).
  Future<void> openMarkdown({
    String? text,
    Uint8List? bytes,
    String? path,
    String? asset,
    String? url,
    String? storageKey,
    UStorageBucket storageBucket = UStorageBucket.vault,
    Map<String, String>? headers,
    String? documentId,
    String? baseUrl,
    Future<Uint8List?> Function(String href)? resourceLoader,
  }) async {
    emit(value.copyWith(state: UDocState.opening, isBusy: true, clearError: true));
    try {
      String content = text ?? "";
      if (text == null) {
        final UCachedByteSource input = await UDocSources.open(path: path, url: url, bytes: bytes, asset: asset, headers: headers, storageKey: storageKey, storageBucket: storageBucket, private: storageKey != null);
        try {
          content = UDocText.decodeBytes(await input.readAll());
        } finally {
          await input.close();
        }
      }
      final String? identity = documentId ?? storageKey ?? path ?? url ?? (asset == null ? null : "asset:$asset");
      _fingerprint = "md-${UHasher.hex(UHashAlgorithm.sha256, utf8.encode(identity ?? content)).substring(0, 24)}";
      _headers = headers;
      _resourceLoader = resourceLoader;
      _baseUrl = baseUrl ?? _folderOf(url);
      _basePath = path != null ? File(path).parent.path : (asset != null && asset.contains("/") ? "asset:${asset.substring(0, asset.lastIndexOf("/"))}" : null);
      _text = content;
      _saved = content;
      await openSource(await _build(content));
    } on UDocError catch (error) {
      failWith(error);
    } on Object catch (error) {
      failWith(UDocError(code: UDocErrorCode.corrupt, message: "Could not open the document", detail: "$error"));
    }
  }

  static String? _folderOf(String? url) {
    if (url == null) return null;
    return url.substring(0, url.lastIndexOf("/") + 1);
  }

  Future<UMarkdownDocument> _build(String content) =>
      UMarkdownDocument.create(content, fingerprint: _fingerprint, chapterLevel: chapterLevel, basePath: _basePath, baseUrl: _baseUrl, headers: _headers, resourceLoader: _resourceLoader);

  /// Replaces the text and refreshes the reader. With [annotations], highlights and notes follow their text to its new place.
  Future<void> setText(String markdown, {UDocAnnotationController? annotations}) async {
    if (markdown == _text && source != null) return;
    final int token = ++_editToken;
    final UMarkdownDocument? before = document;
    final UMarkdownDocument next = await _build(markdown);
    if (token != _editToken || isDisposed) return;
    _text = markdown;
    await replaceSource(next);
    if (annotations != null && before != null) reanchor(annotations, before, next);
    notifyListeners();
  }

  /// Text as it was last opened or saved.
  String get savedText => _saved;

  /// Drops the unsaved edits.
  Future<void> revert({UDocAnnotationController? annotations}) => setText(_saved, annotations: annotations);

  /// The current text is the saved version.
  void markSaved() {
    _saved = _text;
    notifyListeners();
  }

  /// Moves text highlights and notes whose text moved after an edit to where that text is now.
  static void reanchor(UDocAnnotationController annotations, UMarkdownDocument before, UMarkdownDocument after) {
    final Map<String, ({int pageIndex, int blockIndex, int start, int end})> places = <String, ({int pageIndex, int blockIndex, int start, int end})>{};
    final List<UEpubChapter> chapters = after.layout.chapters;
    for (final UDocMarkup markup in annotations.markups) {
      if (markup.blockIndex < 0 || markup.text.isEmpty) continue;
      if (markup.pageIndex < chapters.length) {
        final List<UEpubBlock> blocks = chapters[markup.pageIndex].blocks;
        if (markup.blockIndex < blocks.length) {
          final String current = blocks[markup.blockIndex].text;
          if (markup.end <= current.length && current.substring(markup.start, markup.end) == markup.text) continue;
        }
      }
      ({int pageIndex, int blockIndex, int start, int end})? best;
      int bestDistance = 1 << 30;
      for (int page = 0; page < chapters.length; page++) {
        final List<UEpubBlock> blocks = chapters[page].blocks;
        for (int block = 0; block < blocks.length; block++) {
          final String text = blocks[block].text;
          int index = text.indexOf(markup.text);
          while (index >= 0) {
            final int distance = (page - markup.pageIndex).abs() * 100000 + (block - markup.blockIndex).abs() * 1000 + (index - markup.start).abs();
            if (distance < bestDistance) {
              bestDistance = distance;
              best = (pageIndex: page, blockIndex: block, start: index, end: index + markup.text.length);
            }
            index = text.indexOf(markup.text, index + 1);
          }
        }
      }
      if (best != null) places[markup.id] = best;
    }
    if (places.isNotEmpty) annotations.relocate(places);
  }

  /// HTML of the text ([fullDocument]: a complete page with styles).
  String toHtml({bool fullDocument = true}) => UMarkdown.toHtml(_text, fullDocument: fullDocument, title: value.metadata.title);

  /// The text without Markdown syntax.
  String toPlainText() => UMarkdown.toPlainText(_text);
}
