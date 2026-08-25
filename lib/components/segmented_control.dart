import "package:flutter/cupertino.dart";
import "package:u/utilities.dart";

enum SegmentedStyle { material, cupertino, platformDefault }

class USegmentedControl<T extends Object> extends StatelessWidget {
  final Map<T, String> items;
  final T? selectedValue;
  final ValueChanged<T?> onValueChanged;
  final SegmentedStyle style;
  final EdgeInsets? padding;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;
  final bool enabled;

  const USegmentedControl({
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    super.key,
    this.style = SegmentedStyle.platformDefault,
    this.padding,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final SegmentedStyle effectiveStyle = _getEffectiveStyle(context);

    return effectiveStyle == SegmentedStyle.cupertino ? _buildCupertinoSegmentedControl(context) : _buildMaterialSegmentedControl(context);
  }

  Widget _buildCupertinoSegmentedControl(BuildContext context) => CupertinoSlidingSegmentedControl<T>(
    groupValue: selectedValue,
    onValueChanged: onValueChanged,
    children: items.map(
      (T key, String value) => MapEntry<T, Widget>(
        key,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            value,
            style: TextStyle(
              color: _getCupertinoTextColor(context, key),
              fontWeight: selectedValue == key ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    ),
    backgroundColor: backgroundColor ?? CupertinoColors.systemGrey5,
    thumbColor: selectedColor ?? CupertinoTheme.of(context).primaryColor,
    padding: padding ?? const EdgeInsets.all(2),
  );

  Widget _buildMaterialSegmentedControl(BuildContext context) => UContainer(
    padding: padding ?? const EdgeInsets.all(4),
    color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
    radius: 8,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: items.entries.map((MapEntry<T, String> entry) {
        final bool isSelected = selectedValue == entry.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Material(
              color: isSelected ? (selectedColor ?? Theme.of(context).colorScheme.primary) : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: InkWell(
                onTap: enabled ? () => onValueChanged(entry.key) : null,
                borderRadius: BorderRadius.circular(6),
                child: UContainer(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected
                          ? (selectedColor != null ? _getContrastColor(selectedColor!) : Theme.of(context).colorScheme.onPrimary)
                          : (unselectedColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Color _getCupertinoTextColor(BuildContext context, T key) {
    if (!enabled) return CupertinoColors.systemGrey;
    if (selectedValue == key) {
      return _getContrastColor(selectedColor ?? CupertinoTheme.of(context).primaryColor);
    }
    return CupertinoColors.label;
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use white or black text
    final double luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  SegmentedStyle _getEffectiveStyle(BuildContext context) {
    if (style != SegmentedStyle.platformDefault) return style;

    final bool isCupertino = Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS;

    return isCupertino ? SegmentedStyle.cupertino : SegmentedStyle.material;
  }
}
