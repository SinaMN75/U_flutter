import "package:u/utilities.dart";

/// Kinds of user markup layered on top of PDF pages and EPUB text.
enum UDocMarkupKind { highlight, underline, strikeThrough, squiggly, border, note }

/// How notes attached to markups are shown on the page.
enum UDocNoteDisplay { badge, bubble, hidden }

/// Colors offered for highlights and notes.
abstract final class UDocPalette {
  static const List<Color> colors = <Color>[
    Color(0xFFFFEB3B),
    Color(0xFF8BC34A),
    Color(0xFF4FC3F7),
    Color(0xFFFF8A80),
    Color(0xFFFFB74D),
    Color(0xFFCE93D8),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF212121),
  ];

  static IconData iconOf(UDocMarkupKind kind) {
    switch (kind) {
      case UDocMarkupKind.highlight:
        return Icons.format_color_fill_rounded;
      case UDocMarkupKind.underline:
        return Icons.format_underlined_rounded;
      case UDocMarkupKind.strikeThrough:
        return Icons.format_strikethrough_rounded;
      case UDocMarkupKind.squiggly:
        return Icons.gesture_rounded;
      case UDocMarkupKind.border:
        return Icons.crop_square_rounded;
      case UDocMarkupKind.note:
        return Icons.sticky_note_2_outlined;
    }
  }

  static String labelOf(UDocMarkupKind kind) {
    switch (kind) {
      case UDocMarkupKind.highlight:
        return U.s.highlight;
      case UDocMarkupKind.underline:
        return U.s.underline;
      case UDocMarkupKind.strikeThrough:
        return U.s.strikeThrough;
      case UDocMarkupKind.squiggly:
        return U.s.squiggly;
      case UDocMarkupKind.border:
        return U.s.border;
      case UDocMarkupKind.note:
        return U.s.note;
    }
  }
}

List<double> _rectToList(Rect rect) => <double>[_round(rect.left), _round(rect.top), _round(rect.right), _round(rect.bottom)];

double _round(double value) => (value * 100000).roundToDouble() / 100000;

Rect? _rectFromList(Object? raw) {
  if (raw is! List<Object?> || raw.length != 4) return null;
  final List<double> values = raw.map((Object? value) => (value as num?)?.toDouble() ?? 0).toList();
  return Rect.fromLTRB(values[0], values[1], values[2], values[3]);
}

T _enumOf<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

String _newId() => "${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}";

/// One highlight / underline / note… anchored to a PDF page or an EPUB block.
///
/// PDF markups keep [rects] normalised to 0..1 of the page, so they are drawn
/// exactly where they were made even if text extraction changes later. EPUB
/// markups are anchored by [pageIndex] (spine item), [blockIndex] and the
/// [start]/[end] offsets inside that block's text, which survive re-flow.
@immutable
class UDocMarkup {
  const UDocMarkup({
    required this.id,
    required this.kind,
    required this.pageIndex,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.groupId = "",
    this.blockIndex = -1,
    this.start = 0,
    this.end = 0,
    this.text = "",
    this.rects = const <Rect>[],
    this.note = "",
    this.extra = const <String, Object?>{},
  });

  factory UDocMarkup.create({
    required UDocMarkupKind kind,
    required int pageIndex,
    required Color color,
    String groupId = "",
    int blockIndex = -1,
    int start = 0,
    int end = 0,
    String text = "",
    List<Rect> rects = const <Rect>[],
    String note = "",
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    final DateTime now = DateTime.now();
    return UDocMarkup(
      id: _newId(),
      groupId: groupId,
      kind: kind,
      pageIndex: pageIndex,
      blockIndex: blockIndex,
      start: start,
      end: end,
      text: text,
      rects: rects,
      color: color,
      note: note,
      createdAt: now,
      updatedAt: now,
      extra: extra,
    );
  }

  factory UDocMarkup.fromJson(Map<String, Object?> json) => UDocMarkup(
    id: (json["id"] as String?) ?? _newId(),
    groupId: (json["group"] as String?) ?? "",
    kind: _enumOf(UDocMarkupKind.values, json["kind"], UDocMarkupKind.highlight),
    pageIndex: (json["page"] as num?)?.toInt() ?? 0,
    blockIndex: (json["block"] as num?)?.toInt() ?? -1,
    start: (json["start"] as num?)?.toInt() ?? 0,
    end: (json["end"] as num?)?.toInt() ?? 0,
    text: (json["text"] as String?) ?? "",
    rects: <Rect>[...?(json["rects"] as List<Object?>?)?.map(_rectFromList).whereType<Rect>()],
    color: Color((json["color"] as num?)?.toInt() ?? 0xFFFFEB3B),
    note: (json["note"] as String?) ?? "",
    createdAt: DateTime.tryParse((json["created"] as String?) ?? "") ?? DateTime.now(),
    updatedAt: DateTime.tryParse((json["updated"] as String?) ?? "") ?? DateTime.now(),
    extra: <String, Object?>{...?(json["extra"] as Map<String, Object?>?)},
  );

  final String id;

  /// Markups made by one selection spanning several blocks share a group.
  final String groupId;
  final UDocMarkupKind kind;
  final int pageIndex;
  final int blockIndex;
  final int start;
  final int end;
  final String text;
  final List<Rect> rects;
  final Color color;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, Object?> extra;

  bool get hasNote => note.trim().isNotEmpty;

  bool get isPlaced => rects.isNotEmpty || blockIndex >= 0;

  String get groupKey => groupId.isEmpty ? id : groupId;

  Rect? get bounds => rects.isEmpty ? null : rects.reduce((Rect a, Rect b) => a.expandToInclude(b));

  List<Rect> rectsIn(Size size) => rects.map((Rect rect) => Rect.fromLTRB(rect.left * size.width, rect.top * size.height, rect.right * size.width, rect.bottom * size.height)).toList();

  bool hitTest(Offset normalizedPoint, {double slop = 0.004}) {
    for (final Rect rect in rects) {
      if (rect.inflate(slop).contains(normalizedPoint)) return true;
    }
    return false;
  }

  UDocMarkup copyWith({UDocMarkupKind? kind, Color? color, String? note, List<Rect>? rects, int? start, int? end, String? text, Map<String, Object?>? extra, bool touch = true}) => UDocMarkup(
    id: id,
    groupId: groupId,
    kind: kind ?? this.kind,
    pageIndex: pageIndex,
    blockIndex: blockIndex,
    start: start ?? this.start,
    end: end ?? this.end,
    text: text ?? this.text,
    rects: rects ?? this.rects,
    color: color ?? this.color,
    note: note ?? this.note,
    createdAt: createdAt,
    updatedAt: touch ? DateTime.now() : updatedAt,
    extra: extra ?? this.extra,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    if (groupId.isNotEmpty) "group": groupId,
    "kind": kind.name,
    "page": pageIndex,
    if (blockIndex >= 0) "block": blockIndex,
    "start": start,
    "end": end,
    "text": text,
    if (rects.isNotEmpty) "rects": rects.map(_rectToList).toList(),
    "color": color.toARGB32(),
    if (note.isNotEmpty) "note": note,
    "created": createdAt.toIso8601String(),
    "updated": updatedAt.toIso8601String(),
    if (extra.isNotEmpty) "extra": extra,
  };
}

/// A bookmarked page (PDF) or reading position (EPUB).
@immutable
class UDocBookmark {
  const UDocBookmark({
    required this.id,
    required this.pageIndex,
    required this.createdAt,
    this.title = "",
    this.note = "",
    this.color = const Color(0xFFE53935),
    this.blockIndex = -1,
    this.progress = -1,
  });

  factory UDocBookmark.fromJson(Map<String, Object?> json) => UDocBookmark(
    id: (json["id"] as String?) ?? _newId(),
    pageIndex: (json["page"] as num?)?.toInt() ?? 0,
    blockIndex: (json["block"] as num?)?.toInt() ?? -1,
    progress: (json["progress"] as num?)?.toDouble() ?? -1,
    title: (json["title"] as String?) ?? "",
    note: (json["note"] as String?) ?? "",
    color: Color((json["color"] as num?)?.toInt() ?? 0xFFE53935),
    createdAt: DateTime.tryParse((json["created"] as String?) ?? "") ?? DateTime.now(),
  );

  final String id;
  final int pageIndex;
  final int blockIndex;
  final double progress;
  final String title;
  final String note;
  final Color color;
  final DateTime createdAt;

  UDocBookmark copyWith({String? title, String? note, Color? color}) =>
      UDocBookmark(id: id, pageIndex: pageIndex, blockIndex: blockIndex, progress: progress, title: title ?? this.title, note: note ?? this.note, color: color ?? this.color, createdAt: createdAt);

  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    "page": pageIndex,
    if (blockIndex >= 0) "block": blockIndex,
    if (progress >= 0) "progress": progress,
    if (title.isNotEmpty) "title": title,
    if (note.isNotEmpty) "note": note,
    "color": color.toARGB32(),
    "created": createdAt.toIso8601String(),
  };
}

class _UDocSnapshot {
  const _UDocSnapshot(this.markups, this.bookmarks, this.shapes);

  final List<UDocMarkup> markups;
  final List<UDocBookmark> bookmarks;
  final List<UDocShape> shapes;
}

/// Owns every markup and bookmark of one document.
///
/// Works fully offline (optionally persisted to [ULocalStorage] under
/// [storageKey]) and exposes [export]/[import] so an app can sync the same
/// payload with a server. [onChanged] fires after every user change.
class UDocAnnotationController extends ChangeNotifier {
  UDocAnnotationController({this._storageKey, this.onChanged, String? initialData, this.maxUndo = 60, Color? color, this.author = ""}) : _color = color ?? UDocPalette.colors.first {
    if (initialData != null && initialData.isNotEmpty) import(initialData, notify: false);
  }

  static const int formatVersion = 2;

  final void Function(UDocAnnotationController controller)? onChanged;
  final int maxUndo;
  final String author;

  final List<UDocMarkup> _markups = <UDocMarkup>[];
  final List<UDocBookmark> _bookmarks = <UDocBookmark>[];
  final List<UDocShape> _shapes = <UDocShape>[];
  final List<_UDocSnapshot> _undo = <_UDocSnapshot>[];
  final List<_UDocSnapshot> _redo = <_UDocSnapshot>[];
  Map<int, List<UDocMarkup>>? _byPage;
  Map<int, List<UDocShape>>? _shapesByPage;
  String? _lastShapeEdit;
  DateTime _lastShapeEditAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _saveTimer;

  String? _storageKey;
  Color _color;
  UDocMarkupKind _kind = UDocMarkupKind.highlight;
  DateTime _updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _loaded = false;

  List<UDocMarkup> get markups => List<UDocMarkup>.unmodifiable(_markups);

  List<UDocBookmark> get bookmarks => List<UDocBookmark>.unmodifiable(_bookmarks);

  /// Free drawings, shapes, text boxes and sticky notes (see [UDocShapeLayer]).
  List<UDocShape> get shapes => List<UDocShape>.unmodifiable(_shapes);

  String? get storageKey => _storageKey;

  Color get color => _color;

  UDocMarkupKind get kind => _kind;

  DateTime get updatedAt => _updatedAt;

  bool get canUndo => _undo.isNotEmpty;

  bool get canRedo => _redo.isNotEmpty;

  bool get isEmpty => _markups.isEmpty && _bookmarks.isEmpty && _shapes.isEmpty;

  int get noteCount => _markups.where((UDocMarkup markup) => markup.hasNote).length;

  set color(Color value) {
    _color = value;
    notifyListeners();
  }

  set kind(UDocMarkupKind value) {
    _kind = value;
    notifyListeners();
  }

  /// Binds persistence to [key] (for example after the document fingerprint is known) and loads it.
  Future<void> attachStorage(String key) async {
    if (_storageKey == key && _loaded) return;
    _storageKey = key;
    _loaded = false;
    await load();
  }

  List<UDocMarkup> markupsOn(int pageIndex) {
    final Map<int, List<UDocMarkup>> index = _byPage ??= _buildIndex();
    return index[pageIndex] ?? const <UDocMarkup>[];
  }

  Map<int, List<UDocMarkup>> _buildIndex() {
    final Map<int, List<UDocMarkup>> index = <int, List<UDocMarkup>>{};
    for (final UDocMarkup markup in _markups) {
      (index[markup.pageIndex] ??= <UDocMarkup>[]).add(markup);
    }
    return index;
  }

  /// Shapes of one PDF page / EPUB chapter, in paint order.
  List<UDocShape> shapesOn(int pageIndex) {
    final Map<int, List<UDocShape>> index = _shapesByPage ??= _buildShapeIndex();
    return index[pageIndex] ?? const <UDocShape>[];
  }

  /// Shapes of one EPUB paragraph.
  List<UDocShape> shapesOnBlock(int pageIndex, int blockIndex) => shapesOn(pageIndex).where((UDocShape shape) => shape.blockIndex == blockIndex).toList();

  Map<int, List<UDocShape>> _buildShapeIndex() {
    final Map<int, List<UDocShape>> index = <int, List<UDocShape>>{};
    for (final UDocShape shape in _shapes) {
      (index[shape.pageIndex] ??= <UDocShape>[]).add(shape);
    }
    return index;
  }

  UDocShape? shapeById(String id) {
    for (final UDocShape shape in _shapes) {
      if (shape.id == id) return shape;
    }
    return null;
  }

  UDocMarkup? byId(String id) {
    for (final UDocMarkup markup in _markups) {
      if (markup.id == id) return markup;
    }
    return null;
  }

  List<UDocMarkup> group(String groupKey) => _markups.where((UDocMarkup markup) => markup.groupKey == groupKey).toList();

  /// Markups grouped by selection, sorted in reading order.
  List<List<UDocMarkup>> get grouped {
    final Map<String, List<UDocMarkup>> groups = <String, List<UDocMarkup>>{};
    for (final UDocMarkup markup in _markups) {
      (groups[markup.groupKey] ??= <UDocMarkup>[]).add(markup);
    }
    final List<List<UDocMarkup>> result = groups.values.toList();
    for (final List<UDocMarkup> entries in result) {
      entries.sort(_readingOrder);
    }
    result.sort((List<UDocMarkup> a, List<UDocMarkup> b) => _readingOrder(a.first, b.first));
    return result;
  }

  static int _readingOrder(UDocMarkup a, UDocMarkup b) {
    if (a.pageIndex != b.pageIndex) return a.pageIndex.compareTo(b.pageIndex);
    if (a.blockIndex != b.blockIndex) return a.blockIndex.compareTo(b.blockIndex);
    final Rect? boundsA = a.bounds;
    final Rect? boundsB = b.bounds;
    if (boundsA != null && boundsB != null && (boundsA.top - boundsB.top).abs() > 0.004) return boundsA.top.compareTo(boundsB.top);
    return a.start.compareTo(b.start);
  }

  List<UDocMarkup> search(String query, {UDocMarkupKind? kind, Color? color}) {
    final String needle = UDocText.forSearch(query);
    return _markups.where((UDocMarkup markup) {
      if (kind != null && markup.kind != kind) return false;
      if (color != null && markup.color.toARGB32() != color.toARGB32()) return false;
      if (needle.isEmpty) return true;
      return UDocText.forSearch("${markup.text} ${markup.note}").contains(needle);
    }).toList()..sort(_readingOrder);
  }

  bool isBookmarked(int pageIndex) => bookmarkOn(pageIndex) != null;

  UDocBookmark? bookmarkOn(int pageIndex) {
    for (final UDocBookmark bookmark in _bookmarks) {
      if (bookmark.pageIndex == pageIndex) return bookmark;
    }
    return null;
  }

  _UDocSnapshot _snapshot() => _UDocSnapshot(List<UDocMarkup>.from(_markups), List<UDocBookmark>.from(_bookmarks), List<UDocShape>.from(_shapes));

  void _checkpoint() {
    _lastShapeEdit = null;
    _undo.add(_snapshot());
    if (_undo.length > maxUndo) _undo.removeAt(0);
    _redo.clear();
  }

  void _commit({bool debounce = false}) {
    _byPage = null;
    _shapesByPage = null;
    _updatedAt = DateTime.now();
    notifyListeners();
    _saveTimer?.cancel();
    if (debounce) {
      _saveTimer = Timer(const Duration(milliseconds: 350), _flush);
    } else {
      _flush();
    }
  }

  void _flush() {
    _saveTimer?.cancel();
    _saveTimer = null;
    unawaited(save());
    onChanged?.call(this);
  }

  // ───────── shapes ─────────

  UDocShape addShape(UDocShape shape) {
    _checkpoint();
    _shapes.add(shape);
    _commit();
    return shape;
  }

  /// Replaces a shape. Rapid edits of the same shape (dragging, resizing)
  /// share one undo step and one save.
  void updateShape(UDocShape shape) {
    final int index = _shapes.indexWhere((UDocShape existing) => existing.id == shape.id);
    if (index < 0) return;
    final DateTime now = DateTime.now();
    final bool continuing = _lastShapeEdit == shape.id && now.difference(_lastShapeEditAt) < const Duration(milliseconds: 900);
    if (!continuing) _checkpoint();
    _lastShapeEdit = shape.id;
    _lastShapeEditAt = now;
    _shapes[index] = shape;
    _commit(debounce: true);
  }

  void removeShape(String id) {
    final int index = _shapes.indexWhere((UDocShape shape) => shape.id == id);
    if (index < 0) return;
    _checkpoint();
    _shapes.removeAt(index);
    _commit();
  }

  /// Removes every shape, or only those of [pageIndex].
  void clearShapes({int? pageIndex}) {
    if (!_shapes.any((UDocShape shape) => pageIndex == null || shape.pageIndex == pageIndex)) return;
    _checkpoint();
    _shapes.removeWhere((UDocShape shape) => pageIndex == null || shape.pageIndex == pageIndex);
    _commit();
  }

  void bringShapeToFront(String id) => _reorderShape(id, toFront: true);

  void sendShapeToBack(String id) => _reorderShape(id, toFront: false);

  void _reorderShape(String id, {required bool toFront}) {
    final int index = _shapes.indexWhere((UDocShape shape) => shape.id == id);
    if (index < 0) return;
    _checkpoint();
    final UDocShape shape = _shapes.removeAt(index);
    toFront ? _shapes.add(shape) : _shapes.insert(0, shape);
    _commit();
  }

  /// Copies a shape slightly offset and returns the copy.
  UDocShape? duplicateShape(String id) {
    final UDocShape? shape = shapeById(id);
    if (shape == null) return null;
    final UDocShape copy = shape.translated(const Offset(0.02, 0.02)).placed(copy: true);
    return addShape(copy);
  }

  @override
  void dispose() {
    if (_saveTimer != null) _flush();
    super.dispose();
  }

  UDocMarkup add(UDocMarkup markup) {
    _checkpoint();
    _markups.add(markup);
    _commit();
    return markup;
  }

  void addAll(List<UDocMarkup> markups) {
    if (markups.isEmpty) return;
    _checkpoint();
    _markups.addAll(markups);
    _commit();
  }

  void replace(UDocMarkup markup) {
    final int index = _markups.indexWhere((UDocMarkup existing) => existing.id == markup.id);
    if (index < 0) return;
    _checkpoint();
    _markups[index] = markup;
    _commit();
  }

  /// Updates a whole selection group at once (colour, kind or note).
  void updateGroup(String groupKey, {UDocMarkupKind? kind, Color? color, String? note}) {
    bool changed = false;
    for (int i = 0; i < _markups.length; i++) {
      if (_markups[i].groupKey != groupKey) continue;
      if (!changed) _checkpoint();
      changed = true;
      _markups[i] = _markups[i].copyWith(kind: kind, color: color, note: note);
    }
    if (changed) _commit();
  }

  void remove(String id) {
    final int index = _markups.indexWhere((UDocMarkup markup) => markup.id == id);
    if (index < 0) return;
    _checkpoint();
    _markups.removeAt(index);
    _commit();
  }

  void removeGroup(String groupKey) {
    if (!_markups.any((UDocMarkup markup) => markup.groupKey == groupKey)) return;
    _checkpoint();
    _markups.removeWhere((UDocMarkup markup) => markup.groupKey == groupKey);
    _commit();
  }

  /// Silently stores geometry computed after the fact (no undo entry).
  void resolvePlacement(String id, List<Rect> rects, {int? start, int? end, Map<String, Object?>? extra}) {
    final int index = _markups.indexWhere((UDocMarkup markup) => markup.id == id);
    if (index < 0) return;
    _markups[index] = _markups[index].copyWith(rects: rects, start: start, end: end, extra: extra == null ? null : <String, Object?>{..._markups[index].extra, ...extra}, touch: false);
    _byPage = null;
    notifyListeners();
    unawaited(save());
  }

  UDocBookmark toggleBookmark(int pageIndex, {String title = "", int blockIndex = -1, double progress = -1}) {
    final UDocBookmark? existing = bookmarkOn(pageIndex);
    _checkpoint();
    if (existing != null) {
      _bookmarks.remove(existing);
      _commit();
      return existing;
    }
    final UDocBookmark bookmark = UDocBookmark(id: _newId(), pageIndex: pageIndex, blockIndex: blockIndex, progress: progress, title: title, color: _color, createdAt: DateTime.now());
    _bookmarks
      ..add(bookmark)
      ..sort((UDocBookmark a, UDocBookmark b) => a.pageIndex.compareTo(b.pageIndex));
    _commit();
    return bookmark;
  }

  List<UDocBookmark> bookmarksOn(int pageIndex) => _bookmarks.where((UDocBookmark bookmark) => bookmark.pageIndex == pageIndex).toList();

  /// Adds a position bookmark (several per page/chapter are allowed).
  UDocBookmark addBookmark({required int pageIndex, int blockIndex = -1, double progress = -1, String title = "", String note = ""}) {
    _checkpoint();
    final UDocBookmark bookmark = UDocBookmark(id: _newId(), pageIndex: pageIndex, blockIndex: blockIndex, progress: progress, title: title, note: note, color: _color, createdAt: DateTime.now());
    _bookmarks
      ..add(bookmark)
      ..sort((UDocBookmark a, UDocBookmark b) => a.pageIndex != b.pageIndex ? a.pageIndex.compareTo(b.pageIndex) : a.blockIndex.compareTo(b.blockIndex));
    _commit();
    return bookmark;
  }

  void updateBookmark(UDocBookmark bookmark) {
    final int index = _bookmarks.indexWhere((UDocBookmark existing) => existing.id == bookmark.id);
    if (index < 0) return;
    _checkpoint();
    _bookmarks[index] = bookmark;
    _commit();
  }

  void removeBookmark(String id) {
    if (!_bookmarks.any((UDocBookmark bookmark) => bookmark.id == id)) return;
    _checkpoint();
    _bookmarks.removeWhere((UDocBookmark bookmark) => bookmark.id == id);
    _commit();
  }

  void clear() {
    if (isEmpty) return;
    _checkpoint();
    _markups.clear();
    _bookmarks.clear();
    _shapes.clear();
    _commit();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _lastShapeEdit = null;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
  }

  void redo() {
    if (_redo.isEmpty) return;
    _lastShapeEdit = null;
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
  }

  void _restore(_UDocSnapshot snapshot) {
    _markups
      ..clear()
      ..addAll(snapshot.markups);
    _bookmarks
      ..clear()
      ..addAll(snapshot.bookmarks);
    _shapes
      ..clear()
      ..addAll(snapshot.shapes);
    _commit();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    "version": formatVersion,
    "updated": _updatedAt.toIso8601String(),
    if (author.isNotEmpty) "author": author,
    "markups": _markups.map((UDocMarkup markup) => markup.toJson()).toList(),
    "bookmarks": _bookmarks.map((UDocBookmark bookmark) => bookmark.toJson()).toList(),
    if (_shapes.isNotEmpty) "shapes": _shapes.map((UDocShape shape) => shape.toJson()).toList(),
  };

  /// Base64 of the JSON payload — a compact, transport-safe string for servers.
  String export({bool base64 = true}) {
    final String json = jsonEncode(toJson());
    return base64 ? json.toBase64() : json;
  }

  /// Accepts [export] output (base64 or raw JSON) and the legacy SinApp
  /// `{"markers": [...], "pageMarks": [...]}` format. Returns false when the
  /// payload is not understood.
  bool import(String data, {bool merge = false, bool notify = true}) {
    final Map<String, Object?>? json = decode(data);
    if (json == null) return false;
    final List<UDocMarkup> markups = <UDocMarkup>[];
    final List<UDocBookmark> bookmarks = <UDocBookmark>[];
    final List<UDocShape> shapes = <UDocShape>[];
    if (json.containsKey("markups") || json.containsKey("bookmarks") || json.containsKey("shapes")) {
      for (final Object? entry in (json["shapes"] as List<Object?>?) ?? const <Object?>[]) {
        if (entry is Map<String, Object?>) shapes.add(UDocShape.fromJson(entry));
      }
      for (final Object? entry in (json["markups"] as List<Object?>?) ?? const <Object?>[]) {
        if (entry is Map<String, Object?>) markups.add(UDocMarkup.fromJson(entry));
      }
      for (final Object? entry in (json["bookmarks"] as List<Object?>?) ?? const <Object?>[]) {
        if (entry is Map<String, Object?>) bookmarks.add(UDocBookmark.fromJson(entry));
      }
      _updatedAt = DateTime.tryParse((json["updated"] as String?) ?? "") ?? DateTime.now();
    } else if (json.containsKey("markers") || json.containsKey("pageMarks")) {
      _importLegacy(json, markups, bookmarks);
      _updatedAt = DateTime.now();
    } else {
      return false;
    }
    if (notify) _checkpoint();
    if (!merge) {
      _markups.clear();
      _bookmarks.clear();
      _shapes.clear();
    }
    final Set<String> drawn = _shapes.map((UDocShape shape) => shape.id).toSet();
    _shapes.addAll(shapes.where((UDocShape shape) => !drawn.contains(shape.id)));
    _shapesByPage = null;
    final Set<String> known = _markups.map((UDocMarkup markup) => markup.id).toSet();
    _markups.addAll(markups.where((UDocMarkup markup) => !known.contains(markup.id)));
    final Set<String> marked = _bookmarks.map((UDocBookmark bookmark) => "${bookmark.id}|${bookmark.pageIndex}:${bookmark.blockIndex}").toSet();
    final Set<String> positions = _bookmarks.map((UDocBookmark bookmark) => "${bookmark.pageIndex}:${bookmark.blockIndex}").toSet();
    _bookmarks.addAll(
      bookmarks.where(
        (UDocBookmark bookmark) => !marked.contains("${bookmark.id}|${bookmark.pageIndex}:${bookmark.blockIndex}") && !positions.contains("${bookmark.pageIndex}:${bookmark.blockIndex}"),
      ),
    );
    _bookmarks.sort((UDocBookmark a, UDocBookmark b) => a.pageIndex != b.pageIndex ? a.pageIndex.compareTo(b.pageIndex) : a.blockIndex.compareTo(b.blockIndex));
    _byPage = null;
    if (notify) {
      notifyListeners();
      unawaited(save());
    }
    return true;
  }

  void _importLegacy(Map<String, Object?> json, List<UDocMarkup> markups, List<UDocBookmark> bookmarks) {
    for (final Object? entry in (json["markers"] as List<Object?>?) ?? const <Object?>[]) {
      if (entry is! Map<String, Object?>) continue;
      final Map<String, Object?> range = (entry["range"] as Map<String, Object?>?) ?? const <String, Object?>{};
      final int page = ((entry["pageNumber"] ?? range["pageNumber"]) as num?)?.toInt() ?? 1;
      final String type = (entry["type"] as String?) ?? "highlight";
      final UDocMarkupKind kind = type == "border" ? UDocMarkupKind.border : (type == "text" ? UDocMarkupKind.note : UDocMarkupKind.highlight);
      markups.add(
        UDocMarkup.create(
          kind: kind,
          pageIndex: page - 1,
          color: Color((entry["color"] as num?)?.toInt() ?? 0xFFFFEB3B),
          start: (range["start"] as num?)?.toInt() ?? 0,
          end: (range["end"] as num?)?.toInt() ?? 0,
          text: (range["text"] as String?) ?? "",
          note: (entry["text"] as String?) ?? "",
          extra: const <String, Object?>{"legacy": true},
        ),
      );
    }
    for (final Object? page in (json["pageMarks"] as List<Object?>?) ?? const <Object?>[]) {
      if (page is num) bookmarks.add(UDocBookmark(id: _newId(), pageIndex: page.toInt() - 1, createdAt: DateTime.now()));
    }
  }

  static Map<String, Object?>? decode(String data) {
    final String trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    String json = trimmed;
    if (!trimmed.startsWith("{")) {
      try {
        json = trimmed.fromBase64();
      } on Object {
        return null;
      }
    }
    try {
      final Object? decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : null;
    } on Object {
      return null;
    }
  }

  /// Chooses the most recently updated of two exported payloads (for local vs. server sync).
  static String pickNewest(String first, String second) {
    final Map<String, Object?>? a = decode(first);
    final Map<String, Object?>? b = decode(second);
    if (a == null) return b == null ? "" : second;
    if (b == null) return first;
    final DateTime? timeA = DateTime.tryParse((a["updated"] as String?) ?? "");
    final DateTime? timeB = DateTime.tryParse((b["updated"] as String?) ?? "");
    if (timeA != null && timeB != null) return timeB.isAfter(timeA) ? second : first;
    return second.length > first.length ? second : first;
  }

  Future<void> load() async {
    final String? key = _storageKey;
    _loaded = true;
    if (key == null) return;
    try {
      final String? raw = ULocalStorage.getString(key);
      if (raw == null || raw.isEmpty) return;
      final bool hadData = !isEmpty;
      import(raw, merge: hadData, notify: false);
      _byPage = null;
      notifyListeners();
    } on Object {
      return;
    }
  }

  Future<void> save() async {
    final String? key = _storageKey;
    if (key == null) return;
    try {
      ULocalStorage.set(key, export());
    } on Object {
      return;
    }
  }

  /// A readable Markdown summary of every note, highlight and bookmark.
  String toMarkdown({String title = "", String Function(int pageIndex)? pageLabel}) {
    final String Function(int pageIndex) label = pageLabel ?? (int page) => "${U.s.page} ${page + 1}";
    final StringBuffer buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln("# $title\n");
    if (_bookmarks.isNotEmpty) {
      buffer.writeln("## ${U.s.bookmarks}\n");
      for (final UDocBookmark bookmark in _bookmarks) {
        buffer.writeln("- ${label(bookmark.pageIndex)}${bookmark.title.isEmpty ? "" : " — ${bookmark.title}"}${bookmark.note.isEmpty ? "" : ": ${bookmark.note}"}");
      }
      buffer.writeln();
    }
    if (_markups.isNotEmpty) {
      buffer.writeln("## ${U.s.annotations}\n");
      for (final List<UDocMarkup> entries in grouped) {
        final UDocMarkup first = entries.first;
        final String quote = entries.map((UDocMarkup markup) => markup.text.trim()).where((String text) => text.isNotEmpty).join(" ");
        buffer.writeln("- **${label(first.pageIndex)}** · ${UDocPalette.labelOf(first.kind)}");
        if (quote.isNotEmpty) buffer.writeln("  > $quote");
        if (first.hasNote) buffer.writeln("  ${first.note}");
      }
    }
    final List<UDocShape> written = _shapes.where((UDocShape shape) => shape.hasText).toList()
      ..sort((UDocShape a, UDocShape b) => a.pageIndex != b.pageIndex ? a.pageIndex.compareTo(b.pageIndex) : a.bounds.top.compareTo(b.bounds.top));
    if (written.isNotEmpty) {
      buffer.writeln("\n## ${U.s.drawings}\n");
      for (final UDocShape shape in written) {
        buffer.writeln("- **${label(shape.pageIndex)}** · ${shape.text.trim()}");
      }
    }
    return buffer.toString().trimRight();
  }
}

/// Paints markup geometry. Shared by the PDF page overlay and the EPUB text overlay.
abstract final class UDocMarkupPainter {
  static void paint(Canvas canvas, UDocMarkupKind kind, List<Rect> rects, Color color, {bool selected = false, bool hasNote = false, bool rtl = false, bool drawBadge = true}) {
    if (rects.isEmpty) return;
    switch (kind) {
      case UDocMarkupKind.highlight:
        final Paint fill = Paint()..color = color.withValues(alpha: 0.38);
        for (final Rect rect in rects) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(0.6), Radius.circular(rect.height * 0.12)), fill);
        }
        break;
      case UDocMarkupKind.underline:
        final Paint line = Paint()
          ..color = color
          ..strokeCap = StrokeCap.round;
        for (final Rect rect in rects) {
          line.strokeWidth = max(1.2, rect.height * 0.08);
          canvas.drawLine(Offset(rect.left, rect.bottom - line.strokeWidth / 2), Offset(rect.right, rect.bottom - line.strokeWidth / 2), line);
        }
        break;
      case UDocMarkupKind.strikeThrough:
        final Paint line = Paint()
          ..color = color
          ..strokeCap = StrokeCap.round;
        for (final Rect rect in rects) {
          line.strokeWidth = max(1.2, rect.height * 0.08);
          canvas.drawLine(Offset(rect.left, rect.center.dy), Offset(rect.right, rect.center.dy), line);
        }
        break;
      case UDocMarkupKind.squiggly:
        final Paint wave = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        for (final Rect rect in rects) {
          final double amplitude = max(1, rect.height * 0.08);
          final double step = max(2, rect.height * 0.22);
          wave.strokeWidth = max(1, rect.height * 0.06);
          final Path path = Path()..moveTo(rect.left, rect.bottom - amplitude);
          bool up = true;
          for (double x = rect.left + step; x <= rect.right + 0.1; x += step) {
            path.lineTo(x, up ? rect.bottom - amplitude * 2 : rect.bottom);
            up = !up;
          }
          canvas.drawPath(path, wave);
        }
        break;
      case UDocMarkupKind.border:
        final Paint stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke;
        for (final Rect rect in rects) {
          stroke.strokeWidth = max(1.2, rect.height * 0.07);
          canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(stroke.strokeWidth + 0.5), Radius.circular(rect.height * 0.15)), stroke);
        }
        break;
      case UDocMarkupKind.note:
        final Paint fill = Paint()..color = color.withValues(alpha: 0.16);
        final Paint line = Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (final Rect rect in rects) {
          canvas.drawRect(rect.inflate(0.5), fill);
          _dashed(canvas, Offset(rect.left, rect.bottom), Offset(rect.right, rect.bottom), line, max(2, rect.height * 0.18));
        }
        break;
    }
    if (selected) outline(canvas, rects);
    if (drawBadge && (hasNote || kind == UDocMarkupKind.note)) {
      final Rect anchor = rtl ? rects.first : rects.last;
      final double size = (anchor.height * 0.9).clamp(8, 22).toDouble();
      badge(canvas, Offset(rtl ? anchor.left - size * 0.35 : anchor.right + size * 0.35, anchor.top - size * 0.35), color, size);
    }
  }

  /// Selection outline around every rect of a markup.
  static void outline(Canvas canvas, List<Rect> rects) {
    if (rects.isEmpty) return;
    final Paint paint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    Rect union = rects.first;
    for (final Rect rect in rects) {
      union = union.expandToInclude(rect);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(union.inflate(3), const Radius.circular(3)), paint);
  }

  /// A small folded-corner sticky note centred at [center].
  static void badge(Canvas canvas, Offset center, Color color, double size) {
    final Rect box = Rect.fromCenter(center: center, width: size, height: size);
    final double fold = size * 0.32;
    final Path body = Path()
      ..moveTo(box.left, box.top)
      ..lineTo(box.right - fold, box.top)
      ..lineTo(box.right, box.top + fold)
      ..lineTo(box.right, box.bottom)
      ..lineTo(box.left, box.bottom)
      ..close();
    canvas.drawShadow(body, const Color(0xFF000000), 1.5, false);
    canvas.drawPath(body, Paint()..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.15)!);
    canvas.drawPath(
      Path()
        ..moveTo(box.right - fold, box.top)
        ..lineTo(box.right - fold, box.top + fold)
        ..lineTo(box.right, box.top + fold)
        ..close(),
      Paint()..color = Color.lerp(color, const Color(0xFF000000), 0.25)!,
    );
    final Paint lines = Paint()
      ..color = const Color(0x99000000)
      ..strokeWidth = max(0.6, size * 0.06);
    for (int i = 1; i <= 3; i++) {
      final double y = box.top + size * (0.25 + i * 0.17);
      canvas.drawLine(Offset(box.left + size * 0.18, y), Offset(box.right - size * (i == 1 ? 0.36 : 0.18), y), lines);
    }
  }

  static void _dashed(Canvas canvas, Offset from, Offset to, Paint paint, double dash) {
    final double length = (to - from).distance;
    if (length <= 0) return;
    final Offset step = (to - from) / length;
    double travelled = 0;
    while (travelled < length) {
      final double end = min(travelled + dash, length);
      canvas.drawLine(from + step * travelled, from + step * end, paint);
      travelled += dash * 2;
    }
  }
}

/// Repeated user identification drawn over document pages (e.g. for course material).
@immutable
class UDocWatermark {
  const UDocWatermark({
    required this.lines,
    this.opacity = 0.14,
    this.color = const Color(0xFF000000),
    this.fontSize = 14,
    this.perPage = 2,
    this.randomAngle = true,
    this.angle = -0.5,
    this.seed = 0,
  });

  final List<String> lines;
  final double opacity;
  final Color color;
  final double fontSize;
  final int perPage;
  final bool randomAngle;
  final double angle;
  final int seed;

  bool get isEmpty => lines.every((String line) => line.trim().isEmpty);
}

/// Places [watermark] copies at deterministic pseudo-random spots for [pageIndex].
class UDocWatermarkLayer extends StatelessWidget {
  const UDocWatermarkLayer({required this.watermark, required this.pageIndex, this.scale = 1, super.key});

  final UDocWatermark watermark;
  final int pageIndex;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (watermark.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Random random = Random(pageIndex * 7919 + watermark.seed);
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final double fontSize = watermark.fontSize * scale.clamp(0.5, 3).toDouble();
          final List<Widget> copies = <Widget>[];
          for (int i = 0; i < watermark.perPage; i++) {
            final bool vertical = watermark.randomAngle && random.nextBool();
            final double angle = watermark.randomAngle ? (vertical ? -pi / 2 : (random.nextDouble() - 0.5) * 0.6) : watermark.angle;
            final double band = height / watermark.perPage;
            final double dx = width * (0.08 + random.nextDouble() * 0.5);
            final double dy = band * i + band * (0.15 + random.nextDouble() * 0.55);
            copies.add(
              Positioned(
                left: dx,
                top: dy,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.topLeft,
                  child: Opacity(
                    opacity: watermark.opacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: watermark.lines
                          .map(
                            (String line) => Text(
                              line,
                              textDirection: UDocText.isRtl(line) ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: watermark.color, fontFamily: "Vazir", package: "u", height: 1.3),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            );
          }
          return ClipRect(child: Stack(children: copies));
        },
      ),
    );
  }
}

/// A row of colour swatches.
class UDocColorBar extends StatelessWidget {
  const UDocColorBar({required this.selected, required this.onSelected, this.colors = UDocPalette.colors, this.size = 22, this.onDark = false, super.key});

  final Color selected;
  final ValueChanged<Color> onSelected;
  final List<Color> colors;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: colors
        .map(
          (Color color) => InkResponse(
            onTap: () => onSelected(color),
            radius: size,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.toARGB32() == selected.toARGB32() ? (onDark ? const Color(0xFFFFFFFF) : Theme.of(context).colorScheme.primary) : const Color(0x33000000),
                    width: color.toARGB32() == selected.toARGB32() ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

/// Floating actions shown for a fresh text selection.
class UDocSelectionMenu extends StatelessWidget {
  const UDocSelectionMenu({
    required this.color,
    required this.onColor,
    required this.onMarkup,
    this.kinds = UDocMarkupKind.values,
    this.onCopy,
    this.onShare,
    this.onSearch,
    this.onClose,
    super.key,
  });

  final Color color;
  final ValueChanged<Color> onColor;
  final void Function(UDocMarkupKind kind) onMarkup;
  final List<UDocMarkupKind> kinds;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSearch;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = scheme.onInverseSurface;
    return Material(
      color: scheme.inverseSurface,
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UDocColorBar(selected: color, onSelected: onColor, size: 18, onDark: true),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ...kinds.map(
                    (UDocMarkupKind kind) => _action(UDocPalette.iconOf(kind), UDocPalette.labelOf(kind), () => onMarkup(kind), foreground, tint: kind == UDocMarkupKind.note ? null : color),
                  ),
                  if (onCopy != null) _action(Icons.copy_rounded, U.s.copy, onCopy, foreground),
                  if (onShare != null) _action(Icons.share_rounded, U.s.share, onShare, foreground),
                  if (onSearch != null) _action(Icons.search_rounded, U.s.search, onSearch, foreground),
                  if (onClose != null) _action(Icons.close_rounded, U.s.cancel, onClose, foreground),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String tooltip, VoidCallback? onPressed, Color foreground, {Color? tint}) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
    icon: Icon(icon, size: 20, color: tint ?? foreground),
  );
}

/// Actions for an existing markup (recolour, change style, note, copy, delete).
class UDocMarkupMenu extends StatelessWidget {
  const UDocMarkupMenu({required this.markup, required this.controller, this.allowCopy = true, this.onDone, this.kinds = UDocMarkupKind.values, super.key});

  final UDocMarkup markup;
  final UDocAnnotationController controller;
  final bool allowCopy;
  final VoidCallback? onDone;
  final List<UDocMarkupKind> kinds;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = scheme.onInverseSurface;
    return Material(
      color: scheme.inverseSurface,
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UDocColorBar(
              selected: markup.color,
              size: 18,
              onDark: true,
              onSelected: (Color color) {
                controller.updateGroup(markup.groupKey, color: color);
                onDone?.call();
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ...kinds.map(
                  (UDocMarkupKind kind) => IconButton(
                    tooltip: UDocPalette.labelOf(kind),
                    visualDensity: VisualDensity.compact,
                    isSelected: markup.kind == kind,
                    onPressed: () {
                      controller.updateGroup(markup.groupKey, kind: kind);
                      onDone?.call();
                    },
                    icon: Icon(UDocPalette.iconOf(kind), size: 20, color: markup.kind == kind ? markup.color : foreground),
                  ),
                ),
                IconButton(
                  tooltip: markup.hasNote ? U.s.editNote : U.s.addNote,
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final String? note = await UDocNoteEditor.show(initial: markup.note, quote: markup.text);
                    if (note != null) controller.updateGroup(markup.groupKey, note: note);
                    onDone?.call();
                  },
                  icon: Icon(Icons.edit_note_rounded, size: 22, color: foreground),
                ),
                if (allowCopy && markup.text.isNotEmpty)
                  IconButton(
                    tooltip: U.s.copy,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      unawaited(UClipboard.set(controller.group(markup.groupKey).map((UDocMarkup entry) => entry.text).join("\n")));
                      onDone?.call();
                    },
                    icon: Icon(Icons.copy_rounded, size: 20, color: foreground),
                  ),
                IconButton(
                  tooltip: U.s.delete,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    controller.removeGroup(markup.groupKey);
                    onDone?.call();
                  },
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: scheme.errorContainer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the note editor dialog.
abstract final class UDocNoteEditor {
  /// Returns the edited note, an empty string to clear it, or null when cancelled.
  static Future<String?> show({String initial = "", String quote = ""}) async {
    final TextEditingController field = TextEditingController(text: initial);
    final String? result = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(initial.isEmpty ? U.s.addNote : U.s.editNote),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (quote.trim().isNotEmpty)
                Builder(
                  builder: (BuildContext context) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quote.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textDirection: UDocText.isRtl(quote) ? TextDirection.rtl : TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              TextField(
                controller: field,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(hintText: U.s.writeYourNote, border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text.trim()), child: UTextBodyMedium(U.s.save)),
        ],
      ),
    );
    field.dispose();
    return result;
  }
}

/// Searchable list of every markup and note, grouped per selection.
class UDocAnnotationsPanel extends StatefulWidget {
  const UDocAnnotationsPanel({required this.controller, required this.onOpen, this.pageLabel, this.allowCopy = true, this.title, super.key});

  final UDocAnnotationController controller;
  final void Function(UDocMarkup markup) onOpen;
  final String Function(UDocMarkup markup)? pageLabel;
  final bool allowCopy;
  final String? title;

  @override
  State<UDocAnnotationsPanel> createState() => _UDocAnnotationsPanelState();
}

class _UDocAnnotationsPanelState extends State<UDocAnnotationsPanel> {
  final TextEditingController _query = TextEditingController();
  UDocMarkupKind? _kind;
  bool _notesOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _label(UDocMarkup markup) => widget.pageLabel?.call(markup) ?? "${U.s.page} ${markup.pageIndex + 1}";

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (BuildContext context, Widget? child) {
      final String needle = UDocText.forSearch(_query.text);
      final List<List<UDocMarkup>> groups = widget.controller.grouped.where((List<UDocMarkup> entries) {
        final UDocMarkup first = entries.first;
        if (_kind != null && first.kind != _kind) return false;
        if (_notesOnly && !first.hasNote) return false;
        if (needle.isEmpty) return true;
        return UDocText.forSearch("${entries.map((UDocMarkup markup) => markup.text).join(" ")} ${first.note}").contains(needle);
      }).toList();
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _query,
              onChanged: (String _) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: U.s.search,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FilterChip(label: UTextBodySmall(U.s.notes), selected: _notesOnly, onSelected: (bool value) => setState(() => _notesOnly = value)),
                ),
                ...UDocMarkupKind.values.map(
                  (UDocMarkupKind kind) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      avatar: Icon(UDocPalette.iconOf(kind), size: 16),
                      label: UTextBodySmall(UDocPalette.labelOf(kind)),
                      selected: _kind == kind,
                      onSelected: (bool value) => setState(() => _kind = value ? kind : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: UTextBodyMedium(U.s.noAnnotationsYet, textAlign: TextAlign.center, maxLines: 4),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: groups.length,
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 6),
                    itemBuilder: (BuildContext context, int index) => _tile(context, groups[index]),
                  ),
          ),
        ],
      );
    },
  );

  Widget _tile(BuildContext context, List<UDocMarkup> entries) {
    final UDocMarkup first = entries.first;
    final String quote = entries.map((UDocMarkup markup) => markup.text.trim()).where((String text) => text.isNotEmpty).join(" ");
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onOpen(first),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 5, color: first.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(UDocPalette.iconOf(first.kind), size: 16, color: first.color),
                          const SizedBox(width: 6),
                          Expanded(child: UTextLabelMedium(_label(first), fontWeight: FontWeight.w700)),
                          UTextLabelSmall(first.updatedAt.toLocal().toString().substring(0, 16), color: scheme.onSurfaceVariant),
                          PopupMenuButton<String>(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            onSelected: (String action) => unawaited(_act(action, first, quote)),
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(value: "note", child: UTextBodyMedium(first.hasNote ? U.s.editNote : U.s.addNote)),
                              PopupMenuItem<String>(value: "color", child: UTextBodyMedium(U.s.color)),
                              if (widget.allowCopy && quote.isNotEmpty) PopupMenuItem<String>(value: "copy", child: UTextBodyMedium(U.s.copy)),
                              PopupMenuItem<String>(value: "delete", child: UTextBodyMedium(U.s.delete)),
                            ],
                          ),
                        ],
                      ),
                      if (quote.isNotEmpty)
                        Text(
                          quote,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textDirection: UDocText.isRtl(quote) ? TextDirection.rtl : TextDirection.ltr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      if (first.hasNote)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: first.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
                          child: Text(first.note, textDirection: UDocText.isRtl(first.note) ? TextDirection.rtl : TextDirection.ltr, style: Theme.of(context).textTheme.bodyMedium),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _act(String action, UDocMarkup markup, String quote) async {
    switch (action) {
      case "note":
        final String? note = await UDocNoteEditor.show(initial: markup.note, quote: quote);
        if (note != null) widget.controller.updateGroup(markup.groupKey, note: note);
        break;
      case "color":
        final Color? color = await UNavigator.colorPicker(defaultColor: markup.color, colors: UDocPalette.colors);
        if (color != null) widget.controller.updateGroup(markup.groupKey, color: color);
        break;
      case "copy":
        await UClipboard.set(quote);
        break;
      case "delete":
        final bool confirmed = await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDeleteThisItem(U.s.note), destructive: true);
        if (confirmed) widget.controller.removeGroup(markup.groupKey);
        break;
    }
  }
}

/// List of bookmarked pages / positions.
class UDocBookmarksPanel extends StatelessWidget {
  const UDocBookmarksPanel({required this.controller, required this.onOpen, this.pageLabel, super.key});

  final UDocAnnotationController controller;
  final void Function(UDocBookmark bookmark) onOpen;
  final String Function(UDocBookmark bookmark)? pageLabel;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (BuildContext context, Widget? child) {
      final List<UDocBookmark> bookmarks = controller.bookmarks;
      if (bookmarks.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: UTextBodyMedium(U.s.noBookmarksYet, textAlign: TextAlign.center, maxLines: 4),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: bookmarks.length,
        itemBuilder: (BuildContext context, int index) {
          final UDocBookmark bookmark = bookmarks[index];
          final String label = pageLabel?.call(bookmark) ?? "${U.s.page} ${bookmark.pageIndex + 1}";
          return Card(
            child: ListTile(
              leading: Icon(Icons.bookmark_rounded, color: bookmark.color),
              title: UTextBodyMedium(bookmark.title.isEmpty ? label : bookmark.title, fontWeight: FontWeight.w600),
              subtitle: bookmark.note.isEmpty && bookmark.title.isEmpty
                  ? null
                  : UTextBodySmall(bookmark.title.isEmpty ? bookmark.note : "$label${bookmark.note.isEmpty ? "" : " · ${bookmark.note}"}", maxLines: 2),
              onTap: () => onOpen(bookmark),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: U.s.editNote,
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    onPressed: () async {
                      final String? note = await UDocNoteEditor.show(initial: bookmark.note);
                      if (note != null) controller.updateBookmark(bookmark.copyWith(note: note));
                    },
                  ),
                  IconButton(
                    tooltip: U.s.delete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () => controller.removeBookmark(bookmark.id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Blocks screenshots / screen recording while mounted (reference counted, so
/// nested readers and players don't switch protection off for each other).
class USecureArea extends StatefulWidget {
  const USecureArea({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  static int _holders = 0;

  static Future<void> acquire() async {
    _holders++;
    if (_holders != 1) return;
    try {
      await UScreenGuard.enable();
    } on Object {
      return;
    }
  }

  static Future<void> release() async {
    if (_holders <= 0) return;
    _holders--;
    if (_holders != 0) return;
    try {
      await UScreenGuard.disable();
    } on Object {
      return;
    }
  }

  @override
  State<USecureArea> createState() => _USecureAreaState();
}

class _USecureAreaState extends State<USecureArea> {
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(USecureArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.enabled && !_held) {
      _held = true;
      unawaited(USecureArea.acquire());
    } else if (!widget.enabled && _held) {
      _held = false;
      unawaited(USecureArea.release());
    }
  }

  @override
  void dispose() {
    if (_held) unawaited(USecureArea.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
