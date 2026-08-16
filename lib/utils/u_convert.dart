import "dart:convert";

// =============================================================================
// u_convert — zero-dependency data-format conversions for the `u` plugin:
// JSON <-> XML, JSON <-> CSV, Map <-> query string, and JSON pretty/minify.
// Pure Dart (dart:convert only); no third-party packages.
// =============================================================================

abstract class UConvert {
  // -------------------------------------------------------------------------
  // JSON pretty / minify.
  // -------------------------------------------------------------------------
  static String prettyJson(String json, {int indent = 2}) => JsonEncoder.withIndent(" " * indent).convert(jsonDecode(json));

  static String minifyJson(String json) => jsonEncode(jsonDecode(json));

  static String encodeJson(Object? value, {bool pretty = false, int indent = 2}) => pretty ? JsonEncoder.withIndent(" " * indent).convert(value) : jsonEncode(value);

  static dynamic decodeJson(String json) => jsonDecode(json);

  // -------------------------------------------------------------------------
  // Map <-> query string (x-www-form-urlencoded).
  // -------------------------------------------------------------------------
  static String mapToQueryString(Map<String, dynamic> map) =>
      map.entries.map((MapEntry<String, dynamic> e) => "${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent("${e.value}")}").join("&");

  static Map<String, String> queryStringToMap(String query) {
    final Map<String, String> out = <String, String>{};
    final String clean = query.startsWith("?") ? query.substring(1) : query;
    for (final String part in clean.split("&")) {
      if (part.isEmpty) continue;
      final int i = part.indexOf("=");
      if (i < 0) {
        out[Uri.decodeQueryComponent(part)] = "";
      } else {
        out[Uri.decodeQueryComponent(part.substring(0, i))] = Uri.decodeQueryComponent(part.substring(i + 1));
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // JSON <-> XML.
  // -------------------------------------------------------------------------
  static String jsonToXml(String json, {String rootName = "root", bool pretty = true}) {
    final StringBuffer sb = StringBuffer();
    _emitXml(sb, rootName, jsonDecode(json), pretty ? 0 : -1);
    return sb.toString().trimRight();
  }

  static String valueToXml(Object? value, {String rootName = "root", bool pretty = true}) {
    final StringBuffer sb = StringBuffer();
    _emitXml(sb, rootName, value, pretty ? 0 : -1);
    return sb.toString().trimRight();
  }

  static String xmlToJson(String xml, {bool pretty = false, bool includeRoot = true}) {
    final _XmlNode root = _parseXml(xml);
    final dynamic value = _xmlToValue(root);
    final Object? result = includeRoot ? <String, dynamic>{root.name: value} : value;
    return pretty ? const JsonEncoder.withIndent("  ").convert(result) : jsonEncode(result);
  }

  // -------------------------------------------------------------------------
  // JSON <-> CSV (JSON must be an array of flat objects).
  // -------------------------------------------------------------------------
  static String jsonToCsv(String json, {String delimiter = ","}) {
    final dynamic decoded = jsonDecode(json);
    if (decoded is! List) throw const FormatException("jsonToCsv expects a JSON array of objects.");
    if (decoded.isEmpty) return "";
    final List<String> headers = <String>[];
    for (final dynamic row in decoded) {
      if (row is Map<String, dynamic>) {
        for (final String key in row.keys) {
          if (!headers.contains(key)) headers.add(key);
        }
      }
    }
    final StringBuffer sb = StringBuffer()..writeln(headers.map((String h) => _csvField(h, delimiter)).join(delimiter));
    for (final dynamic row in decoded) {
      final Map<String, dynamic> map = row is Map<String, dynamic> ? row : <String, dynamic>{};
      sb.writeln(headers.map((String h) => _csvField(map[h] == null ? "" : "${map[h]}", delimiter)).join(delimiter));
    }
    return sb.toString().trimRight();
  }

  static String csvToJson(String csv, {String delimiter = ",", bool pretty = false}) {
    final List<List<String>> rows = _parseCsv(csv, delimiter);
    if (rows.isEmpty) return "[]";
    final List<String> headers = rows.first;
    final List<Map<String, String>> out = <Map<String, String>>[];
    for (int i = 1; i < rows.length; i++) {
      final Map<String, String> obj = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        obj[headers[j]] = j < rows[i].length ? rows[i][j] : "";
      }
      out.add(obj);
    }
    return pretty ? const JsonEncoder.withIndent("  ").convert(out) : jsonEncode(out);
  }
}

// ---------------------------------------------------------------------------
// XML emit
// ---------------------------------------------------------------------------

void _emitXml(StringBuffer sb, String name, dynamic value, int indent) {
  final String pad = indent < 0 ? "" : "  " * indent;
  final String nl = indent < 0 ? "" : "\n";
  final int next = indent < 0 ? -1 : indent + 1;
  if (value is Map<String, dynamic>) {
    sb.write("$pad<$name>$nl");
    value.forEach((String k, dynamic v) => _emitXml(sb, k, v, next));
    sb.write("$pad</$name>$nl");
  } else if (value is List) {
    for (final dynamic item in value) {
      _emitXml(sb, name, item, indent);
    }
  } else {
    sb.write("$pad<$name>${_xmlEscape(value == null ? "" : "$value")}</$name>$nl");
  }
}

String _xmlEscape(String s) => s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&apos;");

String _xmlUnescape(String s) => s.replaceAll("&lt;", "<").replaceAll("&gt;", ">").replaceAll("&quot;", '"').replaceAll("&apos;", "'").replaceAll("&amp;", "&");

// ---------------------------------------------------------------------------
// XML parse (elements + text; attributes/comments/declarations ignored)
// ---------------------------------------------------------------------------

class _XmlNode {
  _XmlNode(this.name);

  final String name;
  final List<_XmlNode> children = <_XmlNode>[];
  String text = "";
}

_XmlNode _parseXml(String input) {
  final String xml = input.replaceAll(RegExp(r"<\?[\s\S]*?\?>"), "").replaceAll(RegExp(r"<!--[\s\S]*?-->"), "").trim();
  int i = 0;

  _XmlNode parseElement() {
    i++; // skip '<'
    final int start = i;
    while (i < xml.length && !"> /\t\n\r".contains(xml[i])) {
      i++;
    }
    final _XmlNode node = _XmlNode(xml.substring(start, i));
    while (i < xml.length && xml[i] != ">") {
      if (xml[i] == "/" && i + 1 < xml.length && xml[i + 1] == ">") {
        i += 2;
        return node;
      }
      i++;
    }
    i++; // skip '>'
    final StringBuffer text = StringBuffer();
    while (i < xml.length) {
      if (xml[i] == "<") {
        if (i + 1 < xml.length && xml[i + 1] == "/") {
          i += 2;
          while (i < xml.length && xml[i] != ">") {
            i++;
          }
          i++;
          node.text = _xmlUnescape(text.toString().trim());
          return node;
        }
        node.children.add(parseElement());
      } else {
        text.write(xml[i]);
        i++;
      }
    }
    node.text = _xmlUnescape(text.toString().trim());
    return node;
  }

  while (i < xml.length && xml[i] != "<") {
    i++;
  }
  if (i >= xml.length) return _XmlNode("root");
  return parseElement();
}

dynamic _xmlToValue(_XmlNode node) {
  if (node.children.isEmpty) return node.text;
  final Map<String, dynamic> map = <String, dynamic>{};
  for (final _XmlNode child in node.children) {
    final dynamic value = _xmlToValue(child);
    if (map.containsKey(child.name)) {
      final dynamic existing = map[child.name];
      if (existing is List) {
        existing.add(value);
      } else {
        map[child.name] = <dynamic>[existing, value];
      }
    } else {
      map[child.name] = value;
    }
  }
  return map;
}

// ---------------------------------------------------------------------------
// CSV helpers (RFC 4180-ish)
// ---------------------------------------------------------------------------

String _csvField(String value, String delimiter) {
  if (value.contains(delimiter) || value.contains('"') || value.contains("\n") || value.contains("\r")) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

List<List<String>> _parseCsv(String csv, String delimiter) {
  final List<List<String>> rows = <List<String>>[];
  List<String> row = <String>[];
  final StringBuffer field = StringBuffer();
  bool inQuotes = false;
  final int n = csv.length;
  for (int i = 0; i < n; i++) {
    final String c = csv[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < n && csv[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == delimiter) {
      row.add(field.toString());
      field.clear();
    } else if (c == "\n" || c == "\r") {
      if (c == "\r" && i + 1 < n && csv[i + 1] == "\n") i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
