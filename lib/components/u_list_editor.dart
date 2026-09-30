import "package:u/utilities.dart";

/// One text field of a [UListEditor] row.
class UListEditorField<T> {
  const UListEditorField(this.label, this.value, {this.number = false, this.lines = 1});

  /// Label text.
  final String label;

  /// The field's starting text for an existing item.
  final String? Function(T item) value;

  /// Numbers-only field.
  final bool number;

  /// Number of text lines.
  final int lines;
}

/// Edits a list of items: one card per item with a text field per [fields] entry, a delete button and an add button.
/// [toItem] builds an item from a row's trimmed texts (in [fields] order); returning null leaves the row out.
class UListEditor<T> extends StatefulWidget {
  const UListEditor({
    required this.items,
    required this.fields,
    required this.toItem,
    required this.onChanged,
    required this.addLabel,
    this.title,
    super.key,
  });

  /// Title text.
  final String? title;

  /// The items to show.
  final List<T> items;

  /// Columns of each row.
  final List<UListEditorField<T>> fields;

  /// Builds an item from the typed texts (null = invalid row).
  final T? Function(List<String> texts) toItem;

  /// Called with the new value when the user changes it.
  final ValueChanged<List<T>> onChanged;

  /// Add button text.
  final String addLabel;

  /// A list of short texts (highlights...).
  static UListEditor<String> strings({required List<String> items, required ValueChanged<List<String>> onChanged, required String title, required String addLabel}) => UListEditor<String>(
    title: title,
    items: items,
    addLabel: addLabel,
    onChanged: onChanged,
    fields: <UListEditorField<String>>[UListEditorField<String>(title, (String s) => s)],
    toItem: (List<String> t) => t.first.nullIfEmpty(),
  );

  /// Nearby places of a hotel or dorm: name, distance and walking time.
  static UListEditor<UPlaceNearby> nearby({required List<UPlaceNearby> items, required ValueChanged<List<UPlaceNearby>> onChanged}) => UListEditor<UPlaceNearby>(
    items: items,
    addLabel: U.s.addNearbyPlace,
    onChanged: onChanged,
    fields: <UListEditorField<UPlaceNearby>>[
      UListEditorField<UPlaceNearby>(U.s.title, (UPlaceNearby n) => n.title),
      UListEditorField<UPlaceNearby>(U.s.distanceMeters, (UPlaceNearby n) => n.distanceMeters?.toString(), number: true),
      UListEditorField<UPlaceNearby>(U.s.walkMinutes, (UPlaceNearby n) => n.minutes?.toString(), number: true),
    ],
    toItem: (List<String> t) => t[0].isEmpty ? null : UPlaceNearby(title: t[0], distanceMeters: int.tryParse(t[1].toLatinNumber()), minutes: int.tryParse(t[2].toLatinNumber())),
  );

  /// Frequently asked questions: a row is kept only with both a question and an answer.
  static UListEditor<UPlaceFaq> faqs({required List<UPlaceFaq> items, required ValueChanged<List<UPlaceFaq>> onChanged}) => UListEditor<UPlaceFaq>(
    items: items,
    addLabel: U.s.addQuestion,
    onChanged: onChanged,
    fields: <UListEditorField<UPlaceFaq>>[
      UListEditorField<UPlaceFaq>(U.s.question, (UPlaceFaq f) => f.question),
      UListEditorField<UPlaceFaq>(U.s.answer, (UPlaceFaq f) => f.answer, lines: 3),
    ],
    toItem: (List<String> t) => t[0].isEmpty || t[1].isEmpty ? null : UPlaceFaq(question: t[0], answer: t[1]),
  );

  @override
  State<UListEditor<T>> createState() => _UListEditorState<T>();
}

class _UListEditorState<T> extends State<UListEditor<T>> {
  late final List<List<TextEditingController>> _rows = widget.items.map(_row).toList();

  List<TextEditingController> _row(T? item) => widget.fields.map((UListEditorField<T> f) => TextEditingController(text: item == null ? null : f.value(item))).toList();

  void _emit() => widget.onChanged(_rows.map((List<TextEditingController> r) => widget.toItem(r.map((TextEditingController c) => c.text.trim()).toList())).whereType<T>().toList());

  void _remove(List<TextEditingController> row) {
    setState(() => _rows.remove(row));
    _emit();
    for (final TextEditingController c in row) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    for (final List<TextEditingController> row in _rows) {
      for (final TextEditingController c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    margin: const EdgeInsets.symmetric(vertical: 6),
    children: <Widget>[
      if (widget.title != null) Text(widget.title!, style: Theme.of(context).textTheme.labelLarge),
      ..._rows.map(
        (List<TextEditingController> row) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: URow(
            padding: const EdgeInsets.all(8),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UColumn(
                spacing: 6,
                expanded: 1,
                children: List<Widget>.generate(
                  widget.fields.length,
                  (int i) => TextField(
                    controller: row[i],
                    minLines: widget.fields[i].lines,
                    maxLines: widget.fields[i].lines,
                    keyboardType: widget.fields[i].number ? TextInputType.number : TextInputType.text,
                    onChanged: (_) => _emit(),
                    decoration: InputDecoration(labelText: widget.fields[i].label, isDense: true),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                onPressed: () => _remove(row),
              ),
            ],
          ),
        ),
      ),
      TextButton.icon(onPressed: () => setState(() => _rows.add(_row(null))), icon: const Icon(Icons.add), label: Text(widget.addLabel)),
    ],
  );
}
