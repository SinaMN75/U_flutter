import "package:u/utilities.dart";

class UChipChoice<T> extends StatefulWidget {
  const UChipChoice({
    required this.options,
    required this.selected,
    super.key,
    this.onChanged,
    this.chipBuilder,
    this.isMultiChoice = false,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.scrollController,
    this.scrollable = false,
    this.scrollPhysics,
    this.padding = EdgeInsets.zero,
    this.direction = Axis.horizontal,
    this.selectedChipStyle,
    this.unselectedChipStyle,
  });

  /// List of all available options
  final List<T> options;

  /// Current selected value(s)
  final dynamic selected;

  /// Called when selection changes
  final Function(int index, bool isSelected, T item)? onChanged;

  /// Optional chip builder function
  final Widget Function(T item, bool isSelected, int index)? chipBuilder;

  /// Whether multiple selection is allowed
  final bool isMultiChoice;

  /// Chip spacing
  final double spacing;

  /// Run alignment
  final WrapAlignment alignment;

  /// Run spacing
  final double runSpacing;

  /// Optional scroll controller for the chip list
  final ScrollController? scrollController;

  /// Whether the chips should be scrollable
  final bool scrollable;

  /// Scroll physics for the chip list
  final ScrollPhysics? scrollPhysics;

  /// Padding around the chip list
  final EdgeInsets padding;

  /// Direction of the chip list
  final Axis direction;

  /// Style for selected chips (used in default builder)
  final ChipThemeData? selectedChipStyle;

  /// Style for unselected chips (used in default builder)
  final ChipThemeData? unselectedChipStyle;

  @override
  State<UChipChoice<T>> createState() => _UChipChoiceState<T>();
}

class _UChipChoiceState<T> extends State<UChipChoice<T>> {
  bool _isSelected(T item) {
    if (widget.isMultiChoice) {
      return (widget.selected as List<T>).contains(item);
    } else {
      return widget.selected == item;
    }
  }

  void _handleSelection(T item, int index) {
    final bool isSelected = _isSelected(item);

    if (widget.isMultiChoice) {
      final List<T> updatedSelection = List<T>.from(widget.selected as List<T>);
      if (isSelected) {
        updatedSelection.remove(item);
      } else {
        updatedSelection.add(item);
      }
      widget.onChanged?.call(index, !isSelected, item);
    } else {
      if (!isSelected) {
        widget.onChanged?.call(index, true, item);
      }
    }
  }

  Widget _defaultChipBuilder(T item, bool isSelected, int index) {
    final ThemeData theme = Theme.of(context);
    final ChipThemeData selectedStyle =
        widget.selectedChipStyle ??
        ChipThemeData(
          backgroundColor: theme.colorScheme.primary,
          labelStyle: TextStyle(color: theme.colorScheme.onPrimary),
          side: BorderSide.none,
        );

    final ChipThemeData unselectedStyle =
        widget.unselectedChipStyle ??
        ChipThemeData(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          side: BorderSide(color: theme.colorScheme.outline),
        );

    final ChipThemeData style = isSelected ? selectedStyle : unselectedStyle;

    return ChipTheme(
      data: style,
      child: Chip(
        label: Text(item.toString()).pAll(8),
        onDeleted: isSelected && widget.isMultiChoice ? () => _handleSelection(item, index) : null,
        deleteIconColor: style.labelStyle?.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<GestureDetector> chips = widget.options.asMap().entries.map((MapEntry<int, T> entry) {
      final int index = entry.key;
      final T item = entry.value;
      final bool isSelected = _isSelected(item);

      return GestureDetector(
        onTap: () => _handleSelection(item, index),
        child: widget.chipBuilder != null ? widget.chipBuilder!(item, isSelected, index) : _defaultChipBuilder(item, isSelected, index),
      );
    }).toList();

    if (widget.scrollable) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: widget.scrollPhysics,
        padding: widget.padding,
        scrollDirection: widget.direction,
        child: widget.direction == Axis.horizontal
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: chips.expand((GestureDetector chip) => <Widget>[chip, SizedBox(width: widget.spacing)]).toList()..removeLast(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: chips.expand((GestureDetector chip) => <Widget>[chip, SizedBox(height: widget.spacing)]).toList()..removeLast(),
              ),
      );
    } else {
      return Padding(
        padding: widget.padding,
        child: Wrap(
          spacing: widget.spacing,
          runSpacing: widget.runSpacing,
          alignment: widget.alignment,
          direction: widget.direction,
          children: chips,
        ),
      );
    }
  }
}
