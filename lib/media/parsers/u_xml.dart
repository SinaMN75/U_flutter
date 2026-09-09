import "package:u/utilities.dart";

const int _kMaxDepth = 64;
const int _kMaxNodes = 200000;

class UXmlNode {
  UXmlNode(this.name, this.attributes, this.children, this.text);

  final String name;
  final Map<String, String> attributes;
  final List<UXmlNode> children;
  final String text;

  String? attr(String key) => attributes[key];

  UXmlNode? child(String childName) {
    for (final UXmlNode node in children) {
      if (node.name == childName) return node;
    }
    return null;
  }

  List<UXmlNode> childrenNamed(String childName) => children.where((UXmlNode n) => n.name == childName).toList(growable: false);

  Iterable<UXmlNode> descendants(String childName) sync* {
    for (final UXmlNode node in children) {
      if (node.name == childName) yield node;
      yield* node.descendants(childName);
    }
  }
}

abstract final class UXml {
  static UXmlNode? parse(String source) {
    final _XmlCursor cursor = _XmlCursor(source);
    try {
      return cursor.parseDocument();
    } on UMediaParseException {
      return null;
    }
  }

  static String unescape(String value) {
    if (!value.contains("&")) return value;
    return value
        .replaceAllMapped(RegExp("&#x([0-9a-fA-F]+);"), (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
        .replaceAllMapped(RegExp(r"&#(\d+);"), (Match m) => String.fromCharCode(int.parse(m.group(1)!)))
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", "\"")
        .replaceAll("&apos;", "'")
        .replaceAll("&amp;", "&");
  }
}

class _XmlCursor {
  _XmlCursor(this.source);

  final String source;
  int position = 0;
  int nodeCount = 0;

  UXmlNode? parseDocument() {
    while (position < source.length) {
      _skipWhitespace();
      if (position >= source.length) return null;
      if (!_startsWith("<")) {
        position++;
        continue;
      }
      if (_startsWith("<?") || _startsWith("<!")) {
        _skipDeclaration();
        continue;
      }
      return _parseElement(0);
    }
    return null;
  }

  bool _startsWith(String value) => source.startsWith(value, position);

  void _skipWhitespace() {
    while (position < source.length) {
      final int code = source.codeUnitAt(position);
      if (code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D) {
        position++;
      } else {
        return;
      }
    }
  }

  void _skipDeclaration() {
    if (_startsWith("<!--")) {
      final int end = source.indexOf("-->", position);
      position = end < 0 ? source.length : end + 3;
      return;
    }
    if (_startsWith("<![CDATA[")) {
      final int end = source.indexOf("]]>", position);
      position = end < 0 ? source.length : end + 3;
      return;
    }
    final int end = source.indexOf(">", position);
    position = end < 0 ? source.length : end + 1;
  }

  UXmlNode _parseElement(int depth) {
    if (depth > _kMaxDepth) throw const UMediaParseException("XML nesting too deep");
    if (++nodeCount > _kMaxNodes) throw const UMediaParseException("XML too large");
    position++;
    final String name = _readName();
    final Map<String, String> attributes = <String, String>{};

    while (position < source.length) {
      _skipWhitespace();
      if (_startsWith("/>")) {
        position += 2;
        return UXmlNode(name, attributes, const <UXmlNode>[], "");
      }
      if (_startsWith(">")) {
        position++;
        break;
      }
      final String key = _readName();
      if (key.isEmpty) {
        position++;
        continue;
      }
      _skipWhitespace();
      if (!_startsWith("=")) {
        attributes[key] = "";
        continue;
      }
      position++;
      _skipWhitespace();
      attributes[key] = _readAttributeValue();
    }

    final List<UXmlNode> children = <UXmlNode>[];
    final StringBuffer text = StringBuffer();

    while (position < source.length) {
      if (_startsWith("</")) {
        final int end = source.indexOf(">", position);
        position = end < 0 ? source.length : end + 1;
        break;
      }
      if (_startsWith("<!--") || _startsWith("<?")) {
        _skipDeclaration();
        continue;
      }
      if (_startsWith("<![CDATA[")) {
        final int end = source.indexOf("]]>", position);
        if (end < 0) {
          position = source.length;
          break;
        }
        text.write(source.substring(position + 9, end));
        position = end + 3;
        continue;
      }
      if (_startsWith("<")) {
        children.add(_parseElement(depth + 1));
        continue;
      }
      final int next = source.indexOf("<", position);
      final int stop = next < 0 ? source.length : next;
      text.write(source.substring(position, stop));
      position = stop;
    }

    return UXmlNode(name, attributes, children, UXml.unescape(text.toString().trim()));
  }

  String _readName() {
    final int start = position;
    while (position < source.length) {
      final int code = source.codeUnitAt(position);
      final bool valid = (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A) || (code >= 0x30 && code <= 0x39) || code == 0x3A || code == 0x5F || code == 0x2D || code == 0x2E;
      if (!valid) break;
      position++;
    }
    return source.substring(start, position);
  }

  String _readAttributeValue() {
    if (position >= source.length) return "";
    final String quote = source[position];
    if (quote != "\"" && quote != "'") {
      final int start = position;
      while (position < source.length && source[position] != " " && source[position] != ">") {
        position++;
      }
      return UXml.unescape(source.substring(start, position));
    }
    position++;
    final int start = position;
    final int end = source.indexOf(quote, position);
    if (end < 0) {
      position = source.length;
      return "";
    }
    position = end + 1;
    return UXml.unescape(source.substring(start, end));
  }
}
