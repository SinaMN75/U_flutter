part of "../../../u_admin.dart";

// Building blocks of the "Details & photos" editors of hotels, rooms, dorms and beds.

/// A titled block of fields.
class UAdminSection extends StatelessWidget {
  const UAdminSection({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        const Divider(height: 16),
        ...children,
      ],
    ),
  );
}

/// On/off chips for one group of tags (amenities, meal plans, policies...).
/// [tags] is the whole tag list of the item and is edited in place; [single] keeps at most one of [options] selected (type, approval...).
class UAdminTagChips<T extends UNumericIdentifiable> extends StatefulWidget {
  const UAdminTagChips({required this.title, required this.options, required this.tags, this.single = false, super.key});

  final String title;
  final List<T> options;
  final List<int> tags;
  final bool single;

  @override
  State<UAdminTagChips<T>> createState() => _UAdminTagChipsState<T>();
}

class _UAdminTagChipsState<T extends UNumericIdentifiable> extends State<UAdminTagChips<T>> {
  void _toggle(T option, bool on) => setState(() {
    if (widget.single) widget.tags.removeWhere((int t) => widget.options.any((T o) => o.number == t));
    widget.tags.remove(option.number);
    if (on) widget.tags.add(option.number);
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.options.map((T o) => FilterChip(label: Text(o.localizedTitle), selected: widget.tags.contains(o.number), onSelected: (bool on) => _toggle(o, on))).toList(),
        ),
      ],
    ),
  );
}

/// A list of short texts (highlights).
class UAdminStringList extends StatefulWidget {
  const UAdminStringList({required this.title, required this.items, required this.onChanged, this.addLabel, super.key});

  final String title;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String? addLabel;

  @override
  State<UAdminStringList> createState() => _UAdminStringListState();
}

class _UAdminStringListState extends State<UAdminStringList> {
  late final List<String> _items = List<String>.from(widget.items);
  final TextEditingController _input = TextEditingController();

  void _add() {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _items.add(text));
    _input.clear();
    widget.onChanged(List<String>.from(_items));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (_items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _items
                .map(
                  (String e) => InputChip(
                    label: Text(e),
                    onDeleted: () {
                      setState(() => _items.remove(e));
                      widget.onChanged(List<String>.from(_items));
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 6),
        TextField(
          controller: _input,
          onSubmitted: (_) => _add(),
          decoration: InputDecoration(
            labelText: widget.addLabel ?? U.s.add,
            isDense: true,
            suffixIcon: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _add),
          ),
        ),
      ],
    ),
  );
}

class _NearbyRow {
  _NearbyRow(UPlaceNearby n)
    : title = TextEditingController(text: n.title),
      meters = TextEditingController(text: n.distanceMeters?.toString() ?? ""),
      minutes = TextEditingController(text: n.minutes?.toString() ?? "");

  final TextEditingController title;
  final TextEditingController meters;
  final TextEditingController minutes;

  UPlaceNearby toValue() => UPlaceNearby(title: title.text.trim(), distanceMeters: int.tryParse(meters.text.toLatinNumber()), minutes: int.tryParse(minutes.text.toLatinNumber()));
}

/// Nearby places: name + distance + travel time.
class UAdminNearbyEditor extends StatefulWidget {
  const UAdminNearbyEditor({required this.items, required this.onChanged, super.key});

  final List<UPlaceNearby> items;
  final ValueChanged<List<UPlaceNearby>> onChanged;

  @override
  State<UAdminNearbyEditor> createState() => _UAdminNearbyEditorState();
}

class _UAdminNearbyEditorState extends State<UAdminNearbyEditor> {
  late final List<_NearbyRow> _rows = widget.items.map(_NearbyRow.new).toList();

  void _emit() => widget.onChanged(_rows.map((_NearbyRow r) => r.toValue()).where((UPlaceNearby n) => n.title.isNotEmpty).toList());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      ..._rows.map(
        (_NearbyRow r) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: r.title,
                        onChanged: (_) => _emit(),
                        decoration: InputDecoration(labelText: U.s.title, isDense: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _rows.remove(r));
                        _emit();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: r.meters,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emit(),
                        decoration: InputDecoration(labelText: U.s.distanceMeters, isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: r.minutes,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emit(),
                        decoration: InputDecoration(labelText: U.s.walkMinutes, isDense: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      TextButton.icon(
        onPressed: () => setState(() => _rows.add(_NearbyRow(UPlaceNearby()))),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(U.s.addNearbyPlace),
      ),
    ],
  );
}

class _FaqRow {
  _FaqRow(UPlaceFaq f) : question = TextEditingController(text: f.question), answer = TextEditingController(text: f.answer);

  final TextEditingController question;
  final TextEditingController answer;
}

/// Frequently asked questions.
class UAdminFaqEditor extends StatefulWidget {
  const UAdminFaqEditor({required this.items, required this.onChanged, super.key});

  final List<UPlaceFaq> items;
  final ValueChanged<List<UPlaceFaq>> onChanged;

  @override
  State<UAdminFaqEditor> createState() => _UAdminFaqEditorState();
}

class _UAdminFaqEditorState extends State<UAdminFaqEditor> {
  late final List<_FaqRow> _rows = widget.items.map(_FaqRow.new).toList();

  void _emit() => widget.onChanged(
    _rows.map((_FaqRow r) => UPlaceFaq(question: r.question.text.trim(), answer: r.answer.text.trim())).where((UPlaceFaq f) => f.question.isNotEmpty && f.answer.isNotEmpty).toList(),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      ..._rows.map(
        (_FaqRow r) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: r.question,
                        onChanged: (_) => _emit(),
                        decoration: InputDecoration(labelText: U.s.question, isDense: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _rows.remove(r));
                        _emit();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: r.answer,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => _emit(),
                  decoration: InputDecoration(labelText: U.s.answer, isDense: true),
                ),
              ],
            ),
          ),
        ),
      ),
      TextButton.icon(
        onPressed: () => setState(() => _rows.add(_FaqRow(UPlaceFaq()))),
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(U.s.addQuestion),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------------------------------------------------
// Photos
// ---------------------------------------------------------------------------------------------------------------------

/// What the admin changed in the photo list. It is applied when the dialog is saved (see [UAdminMediaSync]).
class UAdminMediaDraft {
  final List<UFileData> newFiles = <UFileData>[];

  /// Gallery category (a TagMedia number, or null) of each file in [newFiles].
  final List<int?> newFileCategories = <int?>[];
  final Set<String> deletedIds = <String>{};

  /// An existing photo that should become the cover.
  String? coverExistingId;

  /// Index in [newFiles] of a new photo that should become the cover.
  int? coverNewIndex;

  bool get isEmpty => newFiles.isEmpty && deletedIds.isEmpty && coverExistingId == null && coverNewIndex == null;
}

/// The photo manager: shows existing photos and pending uploads; cover, category and delete.
class UAdminMediaManager extends StatefulWidget {
  const UAdminMediaManager({required this.media, required this.draft, super.key});

  final List<UMediaResponse> media;
  final UAdminMediaDraft draft;

  @override
  State<UAdminMediaManager> createState() => _UAdminMediaManagerState();
}

class _UAdminMediaManagerState extends State<UAdminMediaManager> {
  int? _category;

  static const List<TagMedia> _categories = <TagMedia>[TagMedia.exterior, TagMedia.interior, TagMedia.room, TagMedia.bathroom, TagMedia.dining, TagMedia.facility, TagMedia.surroundings];

  UAdminMediaDraft get _draft => widget.draft;

  bool _isCover(UMediaResponse m) => _draft.coverExistingId != null ? _draft.coverExistingId == m.id : (_draft.coverNewIndex == null && m.tags.contains(TagMedia.cover.number));

  String _categoryTitle(List<int> tags) {
    for (final TagMedia c in _categories) {
      if (tags.contains(c.number)) return c.localizedTitle;
    }
    return "";
  }

  Future<void> _pick() => UFile.showFilePicker(
    allowMultiple: true,
    allowedExtensions: const <String>["jpg", "jpeg", "png", "webp"],
    action: (List<UFileData> files) {
      if (files.isEmpty || !mounted) return;
      setState(() {
        for (final UFileData f in files) {
          _draft.newFiles.add(f);
          _draft.newFileCategories.add(_category);
        }
      });
    },
  );

  Widget _tile({required Widget image, required bool isCover, required String caption, required VoidCallback onCover, required VoidCallback onDelete, bool isNew = false}) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 130, height: 90, child: image),
            ),
            if (isCover)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(8)),
                  child: Text(U.s.cover, style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ),
            if (isNew)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(8)),
                  child: const Text("NEW", style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
          ],
        ),
        if (caption.isNotEmpty) Text(caption, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
        Row(
          children: <Widget>[
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: U.s.setAsCover,
              icon: Icon(isCover ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber.shade700),
              onPressed: onCover,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: U.s.delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<UMediaResponse> existing = widget.media.where((UMediaResponse m) => !_draft.deletedIds.contains(m.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(U.s.photoCategory, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _categories
              .map(
                (TagMedia c) => ChoiceChip(
                  label: Text(c.localizedTitle),
                  selected: _category == c.number,
                  onSelected: (bool on) => setState(() => _category = on ? c.number : null),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(onPressed: _pick, icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(U.s.addPhotos)),
        const SizedBox(height: 12),
        if (existing.isEmpty && _draft.newFiles.isEmpty)
          Text(U.s.noPhotosYet)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ...existing.map(
                (UMediaResponse m) => _tile(
                  image: UImage(m.url ?? "", fit: BoxFit.cover),
                  isCover: _isCover(m),
                  caption: _categoryTitle(m.tags),
                  onCover: () => setState(() {
                    _draft.coverExistingId = m.id;
                    _draft.coverNewIndex = null;
                  }),
                  onDelete: () => setState(() {
                    _draft.deletedIds.add(m.id);
                    if (_draft.coverExistingId == m.id) _draft.coverExistingId = null;
                  }),
                ),
              ),
              ...List<Widget>.generate(_draft.newFiles.length, (int i) {
                final UFileData f = _draft.newFiles[i];
                final int? cat = _draft.newFileCategories[i];
                return _tile(
                  isNew: true,
                  image: f.hasBytes ? Image.memory(f.bytes!, fit: BoxFit.cover) : const Icon(Icons.image_outlined),
                  isCover: _draft.coverNewIndex == i,
                  caption: cat == null ? "" : _categories.firstWhere((TagMedia c) => c.number == cat).localizedTitle,
                  onCover: () => setState(() {
                    _draft.coverNewIndex = i;
                    _draft.coverExistingId = null;
                  }),
                  onDelete: () => setState(() {
                    _draft.newFiles.removeAt(i);
                    _draft.newFileCategories.removeAt(i);
                    if (_draft.coverNewIndex == i) {
                      _draft.coverNewIndex = null;
                    } else if (_draft.coverNewIndex != null && _draft.coverNewIndex! > i) {
                      _draft.coverNewIndex = _draft.coverNewIndex! - 1;
                    }
                  }),
                );
              }),
            ],
          ),
      ],
    );
  }
}

/// Applies an [UAdminMediaDraft]: deletes removed photos, uploads new ones and moves the cover mark.
abstract class UAdminMediaSync {
  static Future<void> apply({
    required UAdminMediaDraft draft,
    required List<UMediaResponse> existing,
    String? hotelId,
    String? hotelRoomId,
    String? dormId,
    String? dormRoomId,
    String? dormBedId,
  }) async {
    if (draft.isEmpty) return;

    for (final String id in draft.deletedIds) {
      await UServices.media.delete(
        p: UIdParams(id: id),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }

    final List<String?> uploadedIds = <String?>[];
    for (int i = 0; i < draft.newFiles.length; i++) {
      final int? category = draft.newFileCategories[i];
      final (UResponse<String>? ok, UEmptyResponse? _, String? _) = await UServices.media.create(
        p: UMediaCreateParams(
          file: draft.newFiles[i],
          tag1: TagMedia.image.number,
          tag2: category,
          tag3: draft.coverNewIndex == i ? TagMedia.cover.number : null,
          hotelId: hotelId,
          hotelRoomId: hotelRoomId,
          dormId: dormId,
          dormRoomId: dormRoomId,
          dormBedId: dormBedId,
        ),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
      uploadedIds.add(ok?.result);
    }

    // The cover mark lives on exactly one photo.
    final String? newCoverId = draft.coverExistingId ?? (draft.coverNewIndex == null ? null : uploadedIds[draft.coverNewIndex!]);
    if (newCoverId == null) return;
    for (final UMediaResponse m in existing.where((UMediaResponse m) => m.tags.contains(TagMedia.cover.number) && m.id != newCoverId && !draft.deletedIds.contains(m.id))) {
      await UServices.media.update(
        p: UMediaUpdateParams(id: m.id, removeTags: <int>[TagMedia.cover.number]),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }
    if (draft.coverExistingId != null) {
      await UServices.media.update(
        p: UMediaUpdateParams(id: newCoverId, addTags: <int>[TagMedia.cover.number]),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }
  }
}
