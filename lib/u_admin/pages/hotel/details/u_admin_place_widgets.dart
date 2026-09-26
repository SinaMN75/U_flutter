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

/// Connects a place's photos to a [UFilePicker]: builds its controller, then saves what changed.
abstract class UAdminMediaSync {
  static const List<String> extensions = <String>["jpg", "jpeg", "png", "webp"];

  static List<UFilePickerCategory> get categories => <TagMedia>[
    TagMedia.exterior,
    TagMedia.interior,
    TagMedia.room,
    TagMedia.bathroom,
    TagMedia.dining,
    TagMedia.facility,
    TagMedia.surroundings,
  ].map((TagMedia c) => UFilePickerCategory(value: c.number, title: c.localizedTitle)).toList();

  static UFilePickerController controller(List<UMediaResponse> media) {
    final List<UFileData> existing = media.map((UMediaResponse m) => UFileData(id: m.id, url: m.url, tags: m.tags, name: m.path.fileName)).toList();
    return UFilePickerController(existingFiles: existing, cover: existing.where((UFileData f) => f.tags?.contains(TagMedia.cover.number) ?? false).firstOrNull);
  }

  /// Deletes removed photos, uploads new ones (category = first tag) and moves the cover mark.
  static Future<void> apply({
    required UFilePickerController photos,
    required List<UMediaResponse> existing,
    String? hotelId,
    String? hotelRoomId,
    String? dormId,
    String? dormRoomId,
    String? dormBedId,
  }) async {
    if (!photos.hasChanges) return;

    final Set<String> deletedIds = photos.removedFiles.map((UFileData f) => f.id!).toSet();
    for (final String id in deletedIds) {
      await UServices.media.delete(
        p: UIdParams(id: id),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }

    final List<UFileData> newFiles = photos.files;
    final UFileData? cover = photos.coverChanged ? photos.cover : null;
    final String? coverExistingId = cover?.id;
    final int coverNewIndex = cover != null && cover.id == null ? newFiles.indexOf(cover) : -1;

    final List<String?> uploadedIds = <String?>[];
    for (int i = 0; i < newFiles.length; i++) {
      final (UResponse<String>? ok, UEmptyResponse? _, String? _) = await UServices.media.create(
        p: UMediaCreateParams(
          file: newFiles[i],
          tag1: TagMedia.image.number,
          tag2: newFiles[i].tags?.firstOrNull,
          tag3: coverNewIndex == i ? TagMedia.cover.number : null,
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
    final String? newCoverId = coverExistingId ?? (coverNewIndex < 0 ? null : uploadedIds[coverNewIndex]);
    if (newCoverId == null) return;
    for (final UMediaResponse m in existing.where((UMediaResponse m) => m.tags.contains(TagMedia.cover.number) && m.id != newCoverId && !deletedIds.contains(m.id))) {
      await UServices.media.update(
        p: UMediaUpdateParams(id: m.id, removeTags: <int>[TagMedia.cover.number]),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }
    if (coverExistingId != null) {
      await UServices.media.update(
        p: UMediaUpdateParams(id: newCoverId, addTags: <int>[TagMedia.cover.number]),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }
  }
}
