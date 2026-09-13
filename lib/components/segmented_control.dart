import "package:flutter/cupertino.dart";
import "package:u/utilities.dart";

class USegmentedControl<T extends Object> extends StatefulWidget {
  final Map<T, String> items;
  final T? selectedValue;
  final ValueChanged<T?> onValueChanged;
  final EdgeInsetsGeometry? padding;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;
  final bool enabled;

  const USegmentedControl({
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    super.key,
    this.padding,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  State<USegmentedControl<T>> createState() => _USegmentedControlState<T>();
}

class _USegmentedControlState<T extends Object> extends State<USegmentedControl<T>> {
  late T? _selectedValue = widget.selectedValue;

  @override
  void didUpdateWidget(covariant USegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValue = widget.selectedValue;
    }
  }

  void _select(T? value) {
    if (!widget.enabled) return;
    setState(() => _selectedValue = value);
    widget.onValueChanged(value);
  }

  @override
  Widget build(BuildContext context) => _buildCupertinoSegmentedControl(context);

  Widget _buildCupertinoSegmentedControl(BuildContext context) => IgnorePointer(
    ignoring: !widget.enabled,
    child: CupertinoSlidingSegmentedControl<T>(
      groupValue: _selectedValue,
      onValueChanged: _select,
      children: widget.items.map(
        (T key, String value) => MapEntry<T, Widget>(
          key,
          Text(
            " $value ",
            style: TextStyle(color: _getCupertinoTextColor(context, key), fontWeight: _selectedValue == key ? FontWeight.w600 : FontWeight.normal),
          ).fit(),
        ),
      ),
      backgroundColor: widget.backgroundColor ?? CupertinoColors.systemGrey5,
      thumbColor: widget.selectedColor ?? CupertinoTheme.of(context).primaryColor,
      padding: widget.padding ?? const EdgeInsets.all(2),
    ),
  );

  Color _getCupertinoTextColor(BuildContext context, T key) {
    if (!widget.enabled) {
      return CupertinoColors.systemGrey;
    }

    if (_selectedValue == key) {
      return _getContrastColor(widget.selectedColor ?? CupertinoTheme.of(context).primaryColor);
    }

    return widget.unselectedColor ?? CupertinoColors.label;
  }

  Color _getContrastColor(Color color) => color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
