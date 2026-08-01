part of "u_process.dart";

/// Semantic colors for the process UI. Every value is optional: when null the
/// widgets fall back to the current [Theme] / material defaults, so the process
/// screens stay fully reusable in any app while still letting a host inject its
/// own brand tokens (e.g. `context.colors.accentGreen`).
class UProcessStyle {
  const UProcessStyle({
    this.verifiedColor,
    this.awaitingColor,
    this.currentColor,
    this.onAccentColor,
  });

  final Color? verifiedColor;
  final Color? awaitingColor;
  final Color? currentColor;
  final Color? onAccentColor;

  Color verified(BuildContext context) => verifiedColor ?? Colors.green.shade600;

  Color awaiting(BuildContext context) => awaitingColor ?? Colors.amber.shade700;

  Color current(BuildContext context) => currentColor ?? Theme.of(context).colorScheme.primary;

  Color onAccent(BuildContext context) => onAccentColor ?? Colors.white;
}
