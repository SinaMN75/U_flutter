import "package:u/utilities.dart";

/// Where extra action buttons go: top, bottom, start or end.
enum UNumericKeyboardActionsPosition { right, bottom }

/// An extra button on the numeric keyboard (e.g. "Pay").
class UNumericKeyboardAction {
  const UNumericKeyboardAction({
    required this.onTap,
    this.onLongPress,
    this.label,
    this.icon,
    this.child,
    this.flex = 1,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.enabled = true,
  });

  /// Called when tapped.
  final VoidCallback onTap;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Label text.
  final String? label;

  /// Icon shown with it.
  final IconData? icon;

  /// The widget inside.
  final Widget? child;

  /// Width share among action buttons.
  final int flex;

  /// Background color.
  final Color? backgroundColor;

  /// Text/icon color.
  final Color? foregroundColor;

  /// Corner radius.
  final double? borderRadius;

  /// Font size.
  final double? fontSize;

  /// Font weight.
  final FontWeight? fontWeight;

  /// False disables interaction and greys it out.
  final bool enabled;
}

/// On-screen number pad for PIN, amount and POS screens (no system keyboard). `UNumericKeyboard(onKeyTap: controller.appendCharacter, onBackspace: controller.dropLastCharacter, onBackspaceLongPress: controller.clear)`
class UNumericKeyboard extends StatelessWidget {
  const UNumericKeyboard({
    required this.onKeyTap,
    required this.onBackspace,
    required this.onBackspaceLongPress,
    super.key,
    this.actions = const <UNumericKeyboardAction>[],
    this.actionsPosition = UNumericKeyboardActionsPosition.right,
    this.spacing = 8,
    this.runSpacing = 8,
    this.keyAspectRatio = 1.6,
    this.borderRadius = 12,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.actionBackgroundColor,
    this.actionForegroundColor,
    this.fontSize = 24,
    this.fontWeight,
    this.padding = EdgeInsets.zero,
    this.hapticFeedback = true,
    this.enabled = true,
    this.keyBuilder,
    this.keyBorderColor,
    this.keyBorderWidth = 1,
    this.backspaceChild,
    this.extraKey = "000",
    this.keyHeight,
    this.actionHeight,
  });

  /// Called with the tapped digit.
  final void Function(String value) onKeyTap;

  /// Called by backspace.
  final VoidCallback onBackspace;

  /// Called by holding backspace (clear all).
  final VoidCallback onBackspaceLongPress;

  /// Action widgets/buttons.
  final List<UNumericKeyboardAction> actions;

  /// Where action buttons go.
  final UNumericKeyboardActionsPosition actionsPosition;

  /// Gap between items.
  final double spacing;

  /// Gap between rows.
  final double runSpacing;

  /// Key width / height.
  final double keyAspectRatio;

  /// Corner radius.
  final double borderRadius;

  /// Shadow depth.
  final double elevation;

  /// Background color.
  final Color? backgroundColor;

  /// Text/icon color.
  final Color? foregroundColor;

  /// Action button background.
  final Color? actionBackgroundColor;

  /// Action button text color.
  final Color? actionForegroundColor;

  /// Font size.
  final double? fontSize;

  /// Font weight.
  final FontWeight? fontWeight;

  /// Space inside, around the content.
  final EdgeInsets padding;

  /// Vibrates lightly on interaction (mobile).
  final bool hapticFeedback;

  /// False disables interaction and greys it out.
  final bool enabled;

  /// Your own key widget.
  final Widget Function(BuildContext context, String value)? keyBuilder;

  /// Key border color.
  final Color? keyBorderColor;

  /// Key border width.
  final double keyBorderWidth;

  /// Your own backspace icon.
  final Widget? backspaceChild;

  /// Key left of 0, e.g. "." or "000".
  final String? extraKey;

  /// Fixed key height.
  final double? keyHeight;

  /// Action button height.
  final double? actionHeight;

  static const List<List<String>> _digits = <List<String>>[
    <String>["1", "2", "3"],
    <String>["4", "5", "6"],
    <String>["7", "8", "9"],
  ];

  @override
  Widget build(BuildContext context) {
    final bool sideActions = actions.isNotEmpty && actionsPosition == UNumericKeyboardActionsPosition.right;
    final int columns = sideActions ? 4 : 3;
    final double available = 300 - padding.horizontal;
    final double keyWidth = (available - spacing * (columns - 1)) / columns;
    final double keyHeight = this.keyHeight ?? keyWidth / keyAspectRatio;
    final double gridHeight = keyHeight * 4 + runSpacing * 3;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: gridHeight,
            child: Row(
              children: <Widget>[
                Expanded(child: _grid(context, keyHeight)),
                if (sideActions) ...<Widget>[
                  SizedBox(width: spacing),
                  SizedBox(width: keyWidth, child: _actionColumn(context)),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty && actionsPosition == UNumericKeyboardActionsPosition.bottom) ...<Widget>[
            SizedBox(height: runSpacing),
            SizedBox(height: actionHeight ?? keyHeight, child: _actionRow(context)),
          ],
        ],
      ),
    ).ltr();
  }

  Widget _grid(BuildContext context, double keyHeight) => Column(
    children: <Widget>[
      for (final List<String> row in _digits) ...<Widget>[
        SizedBox(
          height: keyHeight,
          child: Row(
            children: <Widget>[
              for (final String value in row) ...<Widget>[
                Expanded(child: _digitKey(context, value)),
                if (value != row.last) SizedBox(width: spacing),
              ],
            ],
          ),
        ),
        SizedBox(height: runSpacing),
      ],
      SizedBox(
        height: keyHeight,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _actionKey(
                context,
                _backspaceAction,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(child: _digitKey(context, "0")),
            SizedBox(width: spacing),
            Expanded(child: extraKey == null ? const SizedBox.shrink() : _zeroZeroZeroKey(context)),
          ],
        ),
      ),
    ],
  );

  UNumericKeyboardAction get _backspaceAction => UNumericKeyboardAction(
    onTap: onBackspace,
    onLongPress: onBackspaceLongPress,
    icon: backspaceChild == null ? Icons.backspace_outlined : null,
    child: backspaceChild,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
  );

  Widget _actionColumn(BuildContext context) => Column(
    children: <Widget>[
      for (final UNumericKeyboardAction action in actions) ...<Widget>[
        Expanded(flex: action.flex, child: _actionKey(context, action)),
        if (action != actions.last) SizedBox(height: runSpacing),
      ],
      SizedBox(height: runSpacing),
      Expanded(
        child: _actionKey(
          context,
          _backspaceAction,
        ),
      ),
    ],
  );

  Widget _actionRow(BuildContext context) => Row(
    children: <Widget>[
      for (final UNumericKeyboardAction action in actions) ...<Widget>[
        Expanded(flex: action.flex, child: _actionKey(context, action)),
        if (action != actions.last) SizedBox(width: spacing),
      ],
    ],
  );

  Widget _zeroZeroZeroKey(BuildContext context) {
    if (keyBuilder != null) return keyBuilder!(context, extraKey!);
    final Color fg = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return _UKey(
      onTap: () => onKeyTap(extraKey!),
      borderRadius: borderRadius,
      elevation: elevation,
      hapticFeedback: hapticFeedback,
      enabled: enabled,
      border: _keyBorder,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        extraKey!,
        style: context.textTheme.bodyLarge!.copyWith(
          color: fg,
          fontWeight: fontWeight ?? FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _digitKey(BuildContext context, String value) {
    if (keyBuilder != null) return keyBuilder!(context, value);
    final Color fg = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return _UKey(
      onTap: () => onKeyTap(value),
      borderRadius: borderRadius,
      elevation: elevation,
      hapticFeedback: hapticFeedback,
      enabled: enabled,
      border: _keyBorder,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        value,
        style: context.textTheme.bodyLarge!.copyWith(
          color: fg,
          fontWeight: fontWeight ?? FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }

  BorderSide get _keyBorder => keyBorderColor == null ? BorderSide.none : BorderSide(color: keyBorderColor!, width: keyBorderWidth);

  Widget _actionKey(BuildContext context, UNumericKeyboardAction action) {
    final bool isSideOrBottom = actions.contains(action);
    final Color fg = action.foregroundColor ?? (isSideOrBottom ? actionForegroundColor ?? Theme.of(context).colorScheme.onPrimary : foregroundColor ?? Theme.of(context).colorScheme.onSurface);
    final Color bg =
        action.backgroundColor ?? (isSideOrBottom ? actionBackgroundColor ?? Theme.of(context).colorScheme.primary : backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest);

    return _UKey(
      onTap: action.onTap,
      onLongPress: action.onLongPress,
      borderRadius: action.borderRadius ?? borderRadius,
      elevation: elevation,
      hapticFeedback: hapticFeedback,
      enabled: enabled && action.enabled,
      border: isSideOrBottom ? BorderSide.none : _keyBorder,
      backgroundColor: bg,
      child:
          action.child ??
          (action.icon != null
              ? Icon(action.icon, color: fg, size: action.fontSize)
              : Text(
                  action.label ?? "---",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge!.copyWith(
                    color: fg,
                    fontWeight: action.fontWeight ?? FontWeight.w600,
                    fontSize: action.fontSize ?? fontSize,
                  ),
                )),
    );
  }
}

class _UKey extends StatelessWidget {
  const _UKey({
    required this.onTap,
    required this.child,
    required this.borderRadius,
    required this.elevation,
    required this.hapticFeedback,
    required this.enabled,
    required this.backgroundColor,
    this.onLongPress,
    this.border = BorderSide.none,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double borderRadius;
  final double elevation;
  final bool hapticFeedback;
  final bool enabled;
  final Color backgroundColor;
  final BorderSide border;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    return Material(
      color: enabled ? backgroundColor : backgroundColor.withValues(alpha: 0.4),
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: radius, side: border),
      child: InkWell(
        borderRadius: radius,
        onTap: enabled
            ? () {
                if (hapticFeedback) HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        onLongPress: enabled && onLongPress != null
            ? () {
                if (hapticFeedback) HapticFeedback.mediumImpact();
                onLongPress!();
              }
            : null,
        child: Center(child: child),
      ),
    );
  }
}
