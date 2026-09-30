part of "u_process.dart";

/// Colors of the process screens (verified, awaiting, current); null values follow the theme. `UProcessStyle(verifiedColor: Colors.green)`
class UProcessStyle {
  const UProcessStyle({
    this.verifiedColor,
    this.awaitingColor,
    this.currentColor,
    this.onAccentColor,
  });

  /// Color of verified steps.
  final Color? verifiedColor;

  /// Color of steps awaiting review.
  final Color? awaitingColor;

  /// Color of the current step.
  final Color? currentColor;

  /// Text color on those colors.
  final Color? onAccentColor;

  /// Verified color resolved from the theme.
  Color verified(BuildContext context) => verifiedColor ?? Colors.green.shade600;

  /// Awaiting color resolved from the theme.
  Color awaiting(BuildContext context) => awaitingColor ?? Colors.amber.shade700;

  /// Current color resolved from the theme.
  Color current(BuildContext context) => currentColor ?? Theme.of(context).colorScheme.primary;

  /// Text color resolved from the theme.
  Color onAccent(BuildContext context) => onAccentColor ?? Colors.white;
}
