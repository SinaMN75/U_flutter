import "package:u/utilities.dart";

String _noteId() => "${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}";

/// A note pinned to a moment (or a range) of a video / audio track.
@immutable
class UMediaNote {
  const UMediaNote({
    required this.id,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.end,
    this.text = "",
    this.color = const Color(0xFFFFC107),
    this.extra = const <String, Object?>{},
  });

  /// New note at [position] (optionally a range to [end]).
  factory UMediaNote.create({required Duration position, Duration? end, String text = "", Color color = const Color(0xFFFFC107)}) {
    final DateTime now = DateTime.now();
    return UMediaNote(id: _noteId(), position: position, end: end, text: text, color: color, createdAt: now, updatedAt: now);
  }

  /// Reads a note from JSON.
  factory UMediaNote.fromJson(Map<String, Object?> json) => UMediaNote(
    id: (json["id"] as String?) ?? _noteId(),
    position: Duration(milliseconds: (json["ms"] as num?)?.toInt() ?? 0),
    end: json["endMs"] == null ? null : Duration(milliseconds: (json["endMs"]! as num).toInt()),
    text: (json["text"] as String?) ?? "",
    color: Color((json["color"] as num?)?.toInt() ?? 0xFFFFC107),
    createdAt: DateTime.tryParse((json["created"] as String?) ?? "") ?? DateTime.now(),
    updatedAt: DateTime.tryParse((json["updated"] as String?) ?? "") ?? DateTime.now(),
    extra: <String, Object?>{...?(json["extra"] as Map<String, Object?>?)},
  );

  /// Unique id.
  final String id;

  /// Where it is placed.
  final Duration position;

  /// End of a range note (null = a single moment).
  final Duration? end;

  /// Text to show.
  final String text;

  /// Main color (defaults to the theme).
  final Color color;

  /// When the note was created.
  final DateTime createdAt;

  /// When the note was last changed.
  final DateTime updatedAt;

  /// Your own data.
  final Map<String, Object?> extra;

  /// True when the note covers a range.
  bool get isRange => end != null && end! > position;

  /// Copy with some fields changed.
  UMediaNote copyWith({Duration? position, Duration? end, bool clearEnd = false, String? text, Color? color}) => UMediaNote(
    id: id,
    position: position ?? this.position,
    end: clearEnd ? null : (end ?? this.end),
    text: text ?? this.text,
    color: color ?? this.color,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    extra: extra,
  );

  /// Note as JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    "ms": position.inMilliseconds,
    if (end != null) "endMs": end!.inMilliseconds,
    "text": text,
    "color": color.toARGB32(),
    "created": createdAt.toIso8601String(),
    "updated": updatedAt.toIso8601String(),
    if (extra.isNotEmpty) "extra": extra,
  };
}

/// Owns the time-stamped notes of one media item, with persistence,
/// undo/redo and a transport-safe [export]/[import] for server sync.
class UMediaNotesController extends ChangeNotifier {
  UMediaNotesController({this._storageKey, this.onChanged, String? initialData, Color? color, this.maxUndo = 60}) : _color = color ?? const Color(0xFFFFC107) {
    if (initialData != null && initialData.isNotEmpty) import(initialData, notify: false);
  }

  /// Called with the new value when the user changes it.
  final void Function(UMediaNotesController controller)? onChanged;

  /// How many steps undo remembers.
  final int maxUndo;

  final List<UMediaNote> _notes = <UMediaNote>[];
  final List<UDocShape> _shapes = <UDocShape>[];
  final List<(List<UMediaNote>, List<UDocShape>)> _undo = <(List<UMediaNote>, List<UDocShape>)>[];
  final List<(List<UMediaNote>, List<UDocShape>)> _redo = <(List<UMediaNote>, List<UDocShape>)>[];
  String? _lastShapeEdit;
  DateTime _lastShapeEditAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _saveTimer;
  String? _storageKey;
  Color _color;
  DateTime _updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Notes sorted by time.
  List<UMediaNote> get notes => List<UMediaNote>.unmodifiable(_notes);

  /// True when there are no notes.
  bool get isEmpty => _notes.isEmpty && _shapes.isEmpty;

  /// Drawings over the video frame, each visible during its time range.
  List<UDocShape> get shapes => List<UDocShape>.unmodifiable(_shapes);

  /// Drawings to show at [position].
  List<UDocShape> shapesAt(Duration position) => _shapes.where((UDocShape shape) => shape.visibleAt(position)).toList();

  /// Number of notes.
  int get length => _notes.length;

  /// Color for new notes.
  Color get color => _color;

  /// True when undo is possible.
  bool get canUndo => _undo.isNotEmpty;

  /// True when redo is possible.
  bool get canRedo => _redo.isNotEmpty;

  /// Last change time.
  DateTime get updatedAt => _updatedAt;

  /// Key the notes are saved under.
  String? get storageKey => _storageKey;

  /// Color for new notes.
  set color(Color value) {
    _color = value;
    notifyListeners();
  }

  /// Seek-bar markers for every note and drawing.
  List<UVideoMarker> get markers => <UVideoMarker>[
    ..._notes.map((UMediaNote note) => UVideoMarker(start: note.position, end: note.end, label: note.text, color: note.color)),
    ..._shapes
        .where((UDocShape shape) => shape.startMs != null)
        .map(
          (UDocShape shape) => UVideoMarker(
            start: Duration(milliseconds: shape.startMs!),
            end: shape.endMs == null ? null : Duration(milliseconds: shape.endMs!),
            label: shape.hasText ? shape.text : U.s.drawings,
            color: shape.strokeColor,
          ),
        ),
  ];

  /// Finds a note.
  UMediaNote? byId(String id) {
    for (final UMediaNote note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// Notes whose moment (or range) is at [position] within [tolerance].
  List<UMediaNote> activeAt(Duration position, {Duration tolerance = const Duration(seconds: 3)}) => _notes.where((UMediaNote note) {
    if (note.isRange) return position >= note.position && position <= note.end!;
    final Duration delta = position - note.position;
    return delta >= Duration.zero && delta <= tolerance;
  }).toList();

  /// Index of the last note at or before [position], -1 when none.
  int indexBefore(Duration position) {
    int found = -1;
    for (int i = 0; i < _notes.length; i++) {
      if (_notes[i].position <= position) found = i;
    }
    return found;
  }

  /// Notes whose text contains [query].
  List<UMediaNote> search(String query) {
    final String needle = UDocText.forSearch(query);
    if (needle.isEmpty) return notes;
    return _notes.where((UMediaNote note) => UDocText.forSearch(note.text).contains(needle)).toList();
  }

  (List<UMediaNote>, List<UDocShape>) _snapshot() => (List<UMediaNote>.from(_notes), List<UDocShape>.from(_shapes));

  void _checkpoint() {
    _lastShapeEdit = null;
    _undo.add(_snapshot());
    if (_undo.length > maxUndo) _undo.removeAt(0);
    _redo.clear();
  }

  void _commit({bool debounce = false}) {
    _notes.sort((UMediaNote a, UMediaNote b) => a.position.compareTo(b.position));
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

  void _restore((List<UMediaNote>, List<UDocShape>) snapshot) {
    _notes
      ..clear()
      ..addAll(snapshot.$1);
    _shapes
      ..clear()
      ..addAll(snapshot.$2);
    _commit();
  }

  // ───────── drawings ─────────

  /// Adds a drawing shape.
  UDocShape addShape(UDocShape shape) {
    _checkpoint();
    _shapes.add(shape);
    _commit();
    return shape;
  }

  /// Rapid edits of one shape (dragging, resizing) share one undo step.
  void updateShape(UDocShape shape) {
    final int index = _shapes.indexWhere((UDocShape existing) => existing.id == shape.id);
    if (index < 0) return;
    final DateTime now = DateTime.now();
    if (_lastShapeEdit != shape.id || now.difference(_lastShapeEditAt) >= const Duration(milliseconds: 900)) _checkpoint();
    _lastShapeEdit = shape.id;
    _lastShapeEditAt = now;
    _shapes[index] = shape;
    _commit(debounce: true);
  }

  /// Removes a drawing shape.
  void removeShape(String id) {
    if (!_shapes.any((UDocShape shape) => shape.id == id)) return;
    _checkpoint();
    _shapes.removeWhere((UDocShape shape) => shape.id == id);
    _commit();
  }

  /// Removes every drawing, or only those visible at [at].
  void clearShapes({Duration? at}) {
    bool matches(UDocShape shape) => at == null || shape.visibleAt(at);
    if (!_shapes.any(matches)) return;
    _checkpoint();
    _shapes.removeWhere(matches);
    _commit();
  }

  @override
  void dispose() {
    if (_saveTimer != null) _flush();
    super.dispose();
  }

  /// Adds a note at [position]. `notes.add(position: controller.value.position, text: "Important")`
  UMediaNote add({required Duration position, String text = "", Color? color, Duration? end}) {
    final UMediaNote note = UMediaNote.create(position: position, end: end, text: text, color: color ?? _color);
    _checkpoint();
    _notes.add(note);
    _commit();
    return note;
  }

  /// Replaces a note (same id).
  void replace(UMediaNote note) {
    final int index = _notes.indexWhere((UMediaNote existing) => existing.id == note.id);
    if (index < 0) return;
    _checkpoint();
    _notes[index] = note;
    _commit();
  }

  /// Deletes a note.
  void remove(String id) {
    if (!_notes.any((UMediaNote note) => note.id == id)) return;
    _checkpoint();
    _notes.removeWhere((UMediaNote note) => note.id == id);
    _commit();
  }

  /// Deletes every note.
  void clear() {
    if (isEmpty) return;
    _checkpoint();
    _notes.clear();
    _shapes.clear();
    _commit();
  }

  /// Undoes the last change.
  void undo() {
    if (_undo.isEmpty) return;
    _lastShapeEdit = null;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
  }

  /// Redoes an undone change.
  void redo() {
    if (_redo.isEmpty) return;
    _lastShapeEdit = null;
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
  }

  /// All notes as JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    "version": 1,
    "updated": _updatedAt.toIso8601String(),
    "notes": _notes.map((UMediaNote note) => note.toJson()).toList(),
    if (_shapes.isNotEmpty) "shapes": _shapes.map((UDocShape shape) => shape.toJson()).toList(),
  };

  /// All notes as a compact string (base64 by default).
  String export({bool base64 = true}) {
    final String json = jsonEncode(toJson());
    return base64 ? json.toBase64() : json;
  }

  /// Accepts [export] output (base64 or JSON) and the legacy SinApp
  /// `{"markers":[{"seconds":…, "text":…, "color":…}]}` payload.
  bool import(String data, {bool merge = false, bool notify = true}) {
    final Map<String, Object?>? json = UDocAnnotationController.decode(data);
    if (json == null) return false;
    final List<UMediaNote> incoming = <UMediaNote>[];
    final List<UDocShape> drawings = <UDocShape>[];
    for (final Object? entry in (json["shapes"] as List<Object?>?) ?? const <Object?>[]) {
      if (entry is Map<String, Object?>) drawings.add(UDocShape.fromJson(entry));
    }
    if (json["notes"] is List<Object?> || drawings.isNotEmpty) {
      for (final Object? entry in (json["notes"] as List<Object?>?) ?? const <Object?>[]) {
        if (entry is Map<String, Object?>) incoming.add(UMediaNote.fromJson(entry));
      }
      _updatedAt = DateTime.tryParse((json["updated"] as String?) ?? "") ?? DateTime.now();
    } else if (json["markers"] is List<Object?>) {
      for (final Object? entry in json["markers"]! as List<Object?>) {
        if (entry is! Map<String, Object?>) continue;
        final num seconds = (entry["seconds"] as num?) ?? 0;
        incoming.add(
          UMediaNote.create(
            position: Duration(milliseconds: (seconds * 1000).round()),
            text: (entry["text"] as String?) ?? "",
            color: Color((entry["color"] as num?)?.toInt() ?? 0xFFFFC107),
          ),
        );
      }
      _updatedAt = DateTime.now();
    } else {
      return false;
    }
    if (notify) _checkpoint();
    if (!merge) {
      _notes.clear();
      _shapes.clear();
    }
    final Set<String> drawn = _shapes.map((UDocShape shape) => shape.id).toSet();
    _shapes.addAll(drawings.where((UDocShape shape) => !drawn.contains(shape.id)));
    final Set<String> known = _notes.map((UMediaNote note) => note.id).toSet();
    _notes.addAll(incoming.where((UMediaNote note) => !known.contains(note.id)));
    _notes.sort((UMediaNote a, UMediaNote b) => a.position.compareTo(b.position));
    if (notify) {
      notifyListeners();
      unawaited(save());
    }
    return true;
  }

  /// Loads and auto-saves notes under [key].
  Future<void> attachStorage(String key) async {
    if (_storageKey == key) return;
    _storageKey = key;
    await load();
  }

  /// Loads saved notes.
  Future<void> load() async {
    final String? key = _storageKey;
    if (key == null) return;
    try {
      final String? raw = ULocalStorage.getString(key);
      if (raw == null || raw.isEmpty) return;
      import(raw, merge: !isEmpty, notify: false);
      notifyListeners();
    } on Object {
      return;
    }
  }

  /// Saves notes now.
  Future<void> save() async {
    final String? key = _storageKey;
    if (key == null) return;
    try {
      ULocalStorage.set(key, export());
    } on Object {
      return;
    }
  }

  /// Notes as Markdown (for sharing).
  String toMarkdown({String title = ""}) {
    final StringBuffer buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln("# $title\n");
    for (final UMediaNote note in _notes) {
      buffer.writeln("- **${uFormatDuration(note.position)}${note.isRange ? " – ${uFormatDuration(note.end!)}" : ""}** ${note.text}");
    }
    return buffer.toString().trimRight();
  }

  /// Notes as an SRT subtitle file (handy to replay notes as captions).
  String toSrt({Duration length = const Duration(seconds: 4)}) {
    String stamp(Duration value) {
      String two(int n) => n.toString().padLeft(2, "0");
      return "${two(value.inHours)}:${two(value.inMinutes.remainder(60))}:${two(value.inSeconds.remainder(60))},${value.inMilliseconds.remainder(1000).toString().padLeft(3, "0")}";
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < _notes.length; i++) {
      final UMediaNote note = _notes[i];
      buffer
        ..writeln(i + 1)
        ..writeln("${stamp(note.position)} --> ${stamp(note.end ?? note.position + length)}")
        ..writeln(note.text)
        ..writeln();
    }
    return buffer.toString();
  }
}

/// Remembers where playback stopped for each media item.
abstract final class UMediaResume {
  static String _key(String id) => "u_media_resume_${id.hashCode.toUnsigned(32).toRadixString(36)}_${id.length}";

  /// Saved "continue watching" position of [id].
  static Duration? get(String id) {
    try {
      final int? ms = ULocalStorage.getInt(_key(id));
      return ms == null || ms <= 0 ? null : Duration(milliseconds: ms);
    } on Object {
      return null;
    }
  }

  /// Saves the position of [id].
  static void save(String id, Duration position, Duration duration) {
    try {
      final bool nearEnd = duration > Duration.zero && position >= duration - const Duration(seconds: 8);
      if (nearEnd || position < const Duration(seconds: 5)) {
        unawaited(ULocalStorage.remove(_key(id)));
        return;
      }
      ULocalStorage.set(_key(id), position.inMilliseconds);
    } on Object {
      return;
    }
  }

  /// Forgets the position of [id].
  static void clear(String id) {
    try {
      unawaited(ULocalStorage.remove(_key(id)));
    } on Object {
      return;
    }
  }
}

/// Searchable list of time-stamped notes; tapping a note seeks the player.
class UMediaNotesPanel extends StatefulWidget {
  const UMediaNotesPanel({required this.notes, required this.controller, this.onSeek, this.showHeader = true, this.pauseWhileEditing = true, super.key});

  /// The notes.
  final UMediaNotesController notes;

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// Called with a note's time when tapped.
  final void Function(Duration position)? onSeek;

  /// Shows the panel header.
  final bool showHeader;

  /// Pauses playback while typing a note.
  final bool pauseWhileEditing;

  @override
  State<UMediaNotesPanel> createState() => _UMediaNotesPanelState();
}

class _UMediaNotesPanelState extends State<UMediaNotesPanel> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _addNote() => UMediaNotes.addAtCurrentTime(widget.notes, widget.controller, pause: widget.pauseWhileEditing);

  void _seek(UMediaNote note) {
    if (widget.onSeek != null) {
      widget.onSeek!(note.position);
    } else {
      unawaited(widget.controller.seek(note.position));
    }
  }

  Future<void> _edit(UMediaNote note) async {
    final String? text = await UDocNoteEditor.show(initial: note.text, quote: uFormatDuration(note.position));
    if (text != null) widget.notes.replace(note.copyWith(text: text));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.notes,
    builder: (BuildContext context, Widget? child) {
      final List<UMediaNote> notes = widget.notes.search(_query.text);
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return Column(
        children: <Widget>[
          if (widget.showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
              child: Row(
                children: <Widget>[
                  Expanded(child: UTextTitleSmall("${U.s.videoNotes} (${widget.notes.length})")),
                  IconButton(tooltip: U.s.undo, onPressed: widget.notes.canUndo ? widget.notes.undo : null, icon: const Icon(Icons.undo_rounded, size: 20)),
                  PopupMenuButton<String>(
                    tooltip: U.s.more,
                    onSelected: (String action) async {
                      if (action == "share") await UShare.text(widget.notes.toMarkdown());
                      if (action == "copy") {
                        await UClipboard.set(widget.notes.export());
                        UToast.toast(message: U.s.copied);
                      }
                      if (action == "srt") await UShare.text(widget.notes.toSrt());
                      if (action == "import") {
                        final String? data = await UNavigator.inputDialog(title: U.s.importAnnotations, hint: U.s.importAnnotations);
                        if (data != null && data.trim().isNotEmpty && !widget.notes.import(data, merge: true)) UToast.errorToast(message: U.s.thisFieldIsInvalid);
                      }
                      if (action == "clear") {
                        final bool confirmed = await UNavigator.confirmAsync(title: U.s.clearAnnotations, message: U.s.areYouSureYouWantToDeleteThisItem(U.s.notes), destructive: true);
                        if (confirmed) widget.notes.clear();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(value: "share", child: UTextBodyMedium(U.s.exportAnnotations)),
                      PopupMenuItem<String>(value: "copy", child: UTextBodyMedium(U.s.export)),
                      const PopupMenuItem<String>(value: "srt", child: UTextBodyMedium("SRT")),
                      PopupMenuItem<String>(value: "import", child: UTextBodyMedium(U.s.importAnnotations)),
                      PopupMenuItem<String>(value: "clear", child: UTextBodyMedium(U.s.clearAnnotations)),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _query,
                    onChanged: (String _) => setState(() {}),
                    decoration: InputDecoration(isDense: true, hintText: U.s.search, prefixIcon: const Icon(Icons.search_rounded, size: 20), border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => unawaited(_addNote()),
                  icon: const Icon(Icons.add_comment_rounded, size: 18),
                  label: UTextBodySmall(U.s.addNote, color: scheme.onPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: UTextBodyMedium(U.s.noNotesYet, textAlign: TextAlign.center, maxLines: 4),
                    ),
                  )
                : ValueListenableBuilder<UMediaValue>(
                    valueListenable: widget.controller,
                    builder: (BuildContext context, UMediaValue value, Widget? child) {
                      final int current = widget.notes.indexBefore(value.position);
                      final UMediaNote? currentNote = current >= 0 ? widget.notes.notes[current] : null;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                        itemCount: notes.length,
                        itemBuilder: (BuildContext context, int index) {
                          final UMediaNote note = notes[index];
                          final bool active = currentNote?.id == note.id;
                          return Card(
                            color: active ? scheme.primaryContainer : null,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _seek(note),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: note.color, borderRadius: BorderRadius.circular(8)),
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: UTextLabelMedium(
                                          "${uFormatDuration(note.position)}${note.isRange ? "–${uFormatDuration(note.end!)}" : ""}",
                                          color: note.color.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          note.text.isEmpty ? "—" : note.text,
                                          textDirection: UDocText.isRtl(note.text) ? TextDirection.rtl : TextDirection.ltr,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      onSelected: (String action) async {
                                        if (action == "edit") await _edit(note);
                                        if (action == "color") {
                                          final Color? color = await UNavigator.colorPicker(defaultColor: note.color, colors: UDocPalette.colors);
                                          if (color != null) widget.notes.replace(note.copyWith(color: color));
                                        }
                                        if (action == "here") widget.notes.replace(note.copyWith(position: widget.controller.value.position));
                                        if (action == "delete") widget.notes.remove(note.id);
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(value: "edit", child: UTextBodyMedium(U.s.editNote)),
                                        PopupMenuItem<String>(value: "color", child: UTextBodyMedium(U.s.color)),
                                        PopupMenuItem<String>(value: "here", child: UTextBodyMedium(uFormatDuration(widget.controller.value.position))),
                                        PopupMenuItem<String>(value: "delete", child: UTextBodyMedium(U.s.delete)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
}

/// Shortcuts for media notes.
abstract final class UMediaNotes {
  /// Pauses (optionally), asks for the note text and pins it to the current position.
  static Future<UMediaNote?> addAtCurrentTime(UMediaNotesController notes, UMediaController controller, {bool pause = true}) async {
    final Duration position = controller.value.position;
    final bool wasPlaying = controller.value.isPlaying;
    if (pause && wasPlaying) await controller.pause();
    final String? text = await UDocNoteEditor.show(quote: uFormatDuration(position));
    UMediaNote? note;
    if (text != null) note = notes.add(position: position, text: text);
    if (pause && wasPlaying) await controller.play();
    return note;
  }

  /// Opens the notes panel in a bottom sheet.
  static Future<void> showPanel(UMediaNotesController notes, UMediaController controller) => UNavigator.bottomSheet<void>(
    SizedBox(
      height: MediaQuery.sizeOf(navigatorKey.currentContext!).height * 0.7,
      child: UMediaNotesPanel(notes: notes, controller: controller),
    ),
  );
}

/// A watermark that drifts to a new random spot every [interval].
class UMovingWatermark extends StatefulWidget {
  const UMovingWatermark({required this.watermark, this.interval = const Duration(seconds: 12), super.key});

  /// Watermark text painted over the content.
  final UDocWatermark watermark;

  /// How often the watermark jumps to a new spot.
  final Duration interval;

  @override
  State<UMovingWatermark> createState() => _UMovingWatermarkState();
}

class _UMovingWatermarkState extends State<UMovingWatermark> {
  final Random _random = Random();
  Alignment _alignment = const Alignment(-0.7, -0.7);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (Timer timer) {
      if (mounted) setState(() => _alignment = Alignment(_random.nextDouble() * 1.7 - 0.85, _random.nextDouble() * 1.7 - 0.85));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.watermark.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedAlign(
        alignment: _alignment,
        duration: widget.interval * 0.8,
        curve: Curves.easeInOut,
        child: Opacity(
          opacity: widget.watermark.opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.watermark.lines
                .map(
                  (String line) => Text(
                    line,
                    textDirection: UDocText.isRtl(line) ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(
                      fontSize: widget.watermark.fontSize,
                      fontWeight: FontWeight.w800,
                      color: widget.watermark.color,
                      fontFamily: "Vazir",
                      package: "u",
                      shadows: const <Shadow>[Shadow(color: Color(0x66000000), blurRadius: 3)],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Shows [pip] instead of [child] while the controller is in picture-in-picture
/// (on Android the whole activity shrinks into the PiP window).
class UMediaPipSwitcher extends StatelessWidget {
  const UMediaPipSwitcher({required this.controller, required this.child, this.pip, super.key});

  /// Controller to read or change it from code.
  final UMediaController controller;

  /// The widget inside.
  final Widget child;

  /// Widget shown in picture-in-picture mode.
  final Widget? pip;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? built) {
      if (value.pip != UPipState.active || kIsWeb || !UApp.isAndroid) return built!;
      return pip ??
          ColoredBox(
            color: const Color(0xFF000000),
            child: UVideoView(controller: controller),
          );
    },
    child: child,
  );
}
