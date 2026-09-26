import "package:u/cli/core.dart";

class _Entry {
  _Entry(this.key, this.keyStart, this.valueStart, this.valueEnd);

  final String key;
  final int keyStart;
  final int valueStart;
  final int valueEnd;
}

/// A formatting-preserving editor for the top-level `<dict>` of an XML plist
/// (Info.plist, *.entitlements). Only top-level keys are read or written, so keys
/// nested inside e.g. `UIApplicationSceneManifest` are never touched by mistake.
class Plist {
  Plist(this.text) {
    _parse();
  }

  String text;
  final List<_Entry> _entries = <_Entry>[];
  int _dictClose = -1;
  String _indent = "\t";

  void _parse() {
    _entries.clear();
    final int plist = text.indexOf("<plist");
    if (plist < 0) {
      throw EditSkip("not an XML plist");
    }
    int i = text.indexOf("<dict", plist);
    if (i < 0) {
      throw EditSkip("plist has no top-level <dict>");
    }
    if (text.startsWith("<dict/>", i)) {
      text = text.replaceRange(i, i + 7, "<dict>\n</dict>");
    }
    i = text.indexOf(">", i) + 1;
    while (true) {
      i = _skip(i);
      if (i >= text.length) {
        throw EditSkip("malformed plist");
      }
      if (text.startsWith("</dict>", i)) {
        _dictClose = i;
        break;
      }
      if (!text.startsWith("<key>", i)) {
        throw EditSkip("unexpected plist content");
      }
      final int keyStart = i;
      final int keyEnd = text.indexOf("</key>", i);
      final String key = xmlUnescape(text.substring(i + 5, keyEnd));
      i = _skip(keyEnd + 6);
      final int valueEnd = _elementEnd(i);
      _entries.add(_Entry(key, keyStart, i, valueEnd));
      i = valueEnd;
    }
    if (_entries.isNotEmpty) {
      _indent = indentAt(text, _entries.first.keyStart);
    }
  }

  int _skip(int from) {
    int i = from;
    while (i < text.length) {
      final String c = text[i];
      if (c == " " || c == "\t" || c == "\n" || c == "\r") {
        i++;
      } else if (text.startsWith("<!--", i)) {
        i = text.indexOf("-->", i) + 3;
      } else {
        break;
      }
    }
    return i;
  }

  int _elementEnd(int start) {
    final int close = text.indexOf(">", start);
    if (text[close - 1] == "/") {
      return close + 1;
    }
    int depth = 1;
    int i = close + 1;
    while (depth > 0) {
      final int lt = text.indexOf("<", i);
      if (lt < 0) {
        throw EditSkip("malformed plist");
      }
      if (text.startsWith("<!--", lt)) {
        i = text.indexOf("-->", lt) + 3;
        continue;
      }
      final int gt = text.indexOf(">", lt);
      if (text[lt + 1] == "/") {
        depth--;
      } else if (text[gt - 1] != "/") {
        depth++;
      }
      i = gt + 1;
    }
    return i;
  }

  _Entry? _find(String key) {
    for (final _Entry e in _entries) {
      if (e.key == key) {
        return e;
      }
    }
    return null;
  }

  List<String> get keys => _entries.map((_Entry e) => e.key).toList();

  bool has(String key) => _find(key) != null;

  /// The raw XML of a value, e.g. `<string>x</string>`.
  String? raw(String key) {
    final _Entry? e = _find(key);
    return e == null ? null : text.substring(e.valueStart, e.valueEnd);
  }

  String? getString(String key) {
    final String? v = raw(key);
    if (v == null) {
      return null;
    }
    if (v == "<string/>") {
      return "";
    }
    final Match? m = RegExp(r"^<string>([\s\S]*)</string>$").firstMatch(v);
    return m == null ? null : xmlUnescape(m.group(1)!);
  }

  bool? getBool(String key) {
    final String? v = raw(key);
    return v == null ? null : v == "<true/>";
  }

  List<String>? getStringArray(String key) {
    final String? v = raw(key);
    if (v == null || !v.startsWith("<array")) {
      return null;
    }
    return RegExp(r"<string>([\s\S]*?)</string>").allMatches(v).map((Match m) => xmlUnescape(m.group(1)!)).toList();
  }

  void setString(String key, String value) => setRaw(key, (String _) => "<string>${xmlEscape(value)}</string>");

  void setBool(String key, {required bool value}) => setRaw(key, (String _) => value ? "<true/>" : "<false/>");

  void setStringArray(String key, List<String> items) => setRaw(
    key,
    (String indent) => items.isEmpty ? "<array/>" : "<array>\n${items.map((String s) => "$indent\t<string>${xmlEscape(s)}</string>\n").join()}$indent</array>",
  );

  /// Adds [item] to a string array, creating the array when needed. Returns false if it was already there.
  bool addToArray(String key, String item) {
    final List<String> items = getStringArray(key) ?? <String>[];
    if (items.contains(item)) {
      return false;
    }
    setStringArray(key, <String>[...items, item]);
    return true;
  }

  /// Removes [item] from a string array; the key goes away when the array becomes empty.
  void removeFromArray(String key, String item) {
    final List<String>? items = getStringArray(key);
    if (items == null || !items.contains(item)) {
      return;
    }
    final List<String> rest = items.where((String s) => s != item).toList();
    if (rest.isEmpty) {
      remove(key);
    } else {
      setStringArray(key, rest);
    }
  }

  /// Sets a value from raw XML. [build] receives the indentation of the key line so
  /// multi-line values can be laid out to match.
  void setRaw(String key, String Function(String indent) build) {
    final _Entry? e = _find(key);
    if (e != null) {
      text = text.replaceRange(e.valueStart, e.valueEnd, build(indentAt(text, e.keyStart)));
    } else {
      final int at = lineStart(text, _dictClose);
      final String prefix = text.substring(at, _dictClose).trim().isEmpty ? "" : "\n";
      text = text.replaceRange(at, at, "$prefix$_indent<key>${xmlEscape(key)}</key>\n$_indent${build(_indent)}\n");
    }
    _parse();
  }

  void remove(String key) {
    final _Entry? e = _find(key);
    if (e == null) {
      return;
    }
    final int start = lineStart(text, e.keyStart);
    final bool keyAlone = text.substring(start, e.keyStart).trim().isEmpty;
    final int end = lineEnd(text, e.valueEnd);
    final bool valueAlone = text.substring(e.valueEnd, end).trim().isEmpty;
    text = keyAlone && valueAlone ? text.replaceRange(start, end, "") : text.replaceRange(e.keyStart, e.valueEnd, "");
    _parse();
  }
}
