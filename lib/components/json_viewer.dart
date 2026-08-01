import "package:u/utilities.dart";

class UJsonViewer extends StatelessWidget {
  final String jsonString;
  final double fontSize;
  final EdgeInsets padding;

  const UJsonViewer({
    required this.jsonString,
    super.key,
    this.fontSize = 13,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    late String formatted;

    try {
      final dynamic decoded = json.decode(jsonString);
      formatted = const JsonEncoder.withIndent("  ").convert(decoded);
    } catch (e) {
      formatted = jsonString;
    }

    return UContainer(
      padding: padding,
      color: const Color(0xff0F172A),
      radius: 8,
      border: Border.all(color: Colors.white12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText.rich(
          TextSpan(
            style: TextStyle(fontSize: fontSize, fontFamily: "monospace"),
            children: _highlightJson(formatted),
          ),
        ),
      ),
    ).ltr();
  }

  List<TextSpan> _highlightJson(String source) {
    final List<TextSpan> spans = <TextSpan>[];
    final RegExp regex = RegExp(r'("(\\.|[^"\\])*")|(\b\d+(\.\d+)?\b)|\b(true|false|null)\b|[{}\[\]:,]');
    int lastIndex = 0;

    for (final RegExpMatch match in regex.allMatches(source)) {
      if (match.start > lastIndex) {
        spans.add(_text(source.substring(lastIndex, match.start), Colors.white70));
      }

      final String token = match.group(0)!;
      spans.add(_text(token, _colorForToken(token)));
      lastIndex = match.end;
    }

    if (lastIndex < source.length) {
      spans.add(_text(source.substring(lastIndex), Colors.white70));
    }

    return spans;
  }

  TextSpan _text(String text, Color color) => TextSpan(
    text: text,
    style: TextStyle(color: color),
  );

  Color _colorForToken(String token) {
    if (token.startsWith('"')) {
      return token.endsWith('"') && token.contains(":") ? Colors.lightBlueAccent : Colors.lightGreenAccent;
    }

    if (RegExp(r"\b(true|false|null)\b").hasMatch(token)) {
      return Colors.purpleAccent;
    }

    if (RegExp(r"\b\d+(\.\d+)?\b").hasMatch(token)) {
      return Colors.orangeAccent;
    }

    return Colors.white54;
  }
}
