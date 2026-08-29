import "package:u/utilities.dart";

enum UNumericKeyboardActionsPosition { right, bottom }

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

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? label;
  final IconData? icon;
  final Widget? child;
  final int flex;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool enabled;
}

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
    this.fontSize,
    this.fontWeight,
    this.padding = EdgeInsets.zero,
    this.hapticFeedback = true,
    this.enabled = true,
    this.keyBuilder,
  });

  final void Function(String value) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onBackspaceLongPress;
  final List<UNumericKeyboardAction> actions;
  final UNumericKeyboardActionsPosition actionsPosition;
  final double spacing;
  final double runSpacing;
  final double keyAspectRatio;
  final double borderRadius;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? actionBackgroundColor;
  final Color? actionForegroundColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets padding;
  final bool hapticFeedback;
  final bool enabled;
  final Widget Function(BuildContext context, String value)? keyBuilder;

  static const List<List<String>> _digits = <List<String>>[
    <String>["1", "2", "3"],
    <String>["4", "5", "6"],
    <String>["7", "8", "9"],
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool sideActions = actions.isNotEmpty && actionsPosition == UNumericKeyboardActionsPosition.right;
      final int columns = sideActions ? 4 : 3;
      final double available = constraints.maxWidth - padding.horizontal;
      final double keyWidth = (available - spacing * (columns - 1)) / columns;
      final double keyHeight = keyWidth / keyAspectRatio;
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
              SizedBox(height: keyHeight, child: _actionRow(context)),
            ],
          ],
        ),
      );
    },
  ).ltr();

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
                UNumericKeyboardAction(
                  onTap: onBackspace,
                  onLongPress: onBackspaceLongPress,
                  icon: Icons.backspace_outlined,
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(child: _digitKey(context, "0")),
            SizedBox(width: spacing),
            Expanded(child: _zeroZeroZeroKey(context)),
          ],
        ),
      ),
    ],
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
          UNumericKeyboardAction(
            onTap: onBackspace,
            onLongPress: onBackspaceLongPress,
            icon: Icons.backspace_outlined,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
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
    if (keyBuilder != null) return keyBuilder!(context, "000");
    final Color fg = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return _UKey(
      onTap: () => onKeyTap("000"),
      borderRadius: borderRadius,
      elevation: elevation,
      hapticFeedback: hapticFeedback,
      enabled: enabled,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: UTextHeadlineSmall(
        "000",
        color: fg,
        fontWeight: fontWeight ?? FontWeight.w600,
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
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      child: UTextHeadlineSmall(
        value,
        color: fg,
        fontWeight: fontWeight ?? FontWeight.w600,
      ),
    );
  }

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
      backgroundColor: bg,
      child:
          action.child ??
          (action.icon != null
              ? Icon(action.icon, color: fg, size: action.fontSize)
              : UTextTitleMedium(
                  action.label ?? "---",
                  color: fg,
                  fontWeight: action.fontWeight ?? FontWeight.w600,
                  textAlign: TextAlign.center,
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
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double borderRadius;
  final double elevation;
  final bool hapticFeedback;
  final bool enabled;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    return Material(
      color: enabled ? backgroundColor : backgroundColor.withValues(alpha: 0.4),
      elevation: elevation,
      borderRadius: radius,
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
