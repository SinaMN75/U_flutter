import "dart:ui" show ImageFilter;

import "package:u/utilities.dart";

class UListTile extends StatelessWidget {
  const UListTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.textColor,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => UPressable(
    onTap: onTap,
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        leading: UIconBackground(icon, color: color ?? Theme.of(context).colorScheme.primary),
        title: UTextBodyMedium(title, color: textColor, fontWeight: FontWeight.bold),
        subtitle: subtitle == null ? null : UTextLabelSmall(subtitle!, color: textColor?.withValues(alpha: 0.6)),
        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).disabledColor, size: 16),
      ),
    ),
  );
}

class UIconBackground extends StatelessWidget {
  const UIconBackground(this.icon, {required this.color, this.size = 42, super.key});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => UContainer(
    width: size,
    height: size,
    alignment: Alignment.center,
    color: color.withValues(alpha: 0.2),
    radius: 12,
    child: Icon(icon, color: color, size: size / 1.8),
  );
}

class UImageBackground extends StatelessWidget {
  const UImageBackground(this.asset, {required this.color, this.size = 42, super.key});

  final String asset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => UContainer(
    width: size,
    height: size,
    alignment: Alignment.center,
    color: color.withValues(alpha: 0.2),
    radius: 12,
    child: UImage(asset, color: color, width: size / 1.8, height: size / 1.8),
  );
}

class UGlassCard extends StatelessWidget {
  const UGlassCard({
    required this.child,
    super.key,
    this.tint,
    this.blur = 12,
    this.opacity = 0.22,
    this.borderRadius = 20,
    this.shadowBlur = 30,
    this.shadowOpacity = 0.0,
  });

  final Widget child;
  final Color? tint;
  final double blur;
  final double opacity;
  final double borderRadius;
  final double shadowBlur;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final Color glassTint = tint ?? Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: shadowOpacity),
            blurRadius: shadowBlur,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glassTint.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: glassTint.withValues(alpha: 0.3)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class UHeaderCard extends StatelessWidget {
  const UHeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      radius: 20,
      padding: const EdgeInsets.all(20),
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UIconBackground(icon, color: iconColor ?? scheme.primary),
          const SizedBox(height: 14),
          UTextTitleMedium(title, color: scheme.onSurface, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          UTextBodySmall(subtitle, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class UEmptyState extends StatelessWidget {
  const UEmptyState({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) => UIconTextVertical(
    leading: UTextBodySmall(title ?? U.s.noData, color: Theme.of(context).colorScheme.onSurfaceVariant).alignAtCenter(),
    trailing: const SizedBox(),
  );
}

class UErrorRetry extends StatelessWidget {
  const UErrorRetry({
    required this.onTap,
    super.key,
    this.title,
    this.buttonTitle,
  });

  final VoidCallback onTap;
  final String? title;
  final String? buttonTitle;

  @override
  Widget build(BuildContext context) => UIconTextVertical(
    leading: UTextBodyMedium(title ?? U.s.errorLoadingData),
    trailing: UButton(title: buttonTitle ?? U.s.tryAgain, onTap: onTap),
  );
}

class UPill extends StatelessWidget {
  const UPill(
    this.label, {
    super.key,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return UContainer(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: foreground.withValues(alpha: 0.12),
      child: URow(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) Icon(icon, size: 14, color: foreground),
          UTextLabelMedium(label, color: foreground, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

class USelectionCard extends StatelessWidget {
  const USelectionCard({
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.pills = const <Widget>[],
    this.trailing,
    this.isSelected = false,
    this.isDisabled = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> pills;
  final Widget? trailing;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      radius: 20,
      padding: const EdgeInsets.all(18),
      color: scheme.surface,
      opacity: isDisabled ? 0.55 : 1,
      onTap: isDisabled ? null : onTap,
      border: Border.all(
        color: isSelected ? scheme.primary : scheme.outlineVariant,
        width: isSelected ? 2 : 1,
      ),
      child: UColumn(
        spacing: 12,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UColumn(
                spacing: 5,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextTitleLarge(title, color: scheme.onSurface),
                  if (subtitle != null) UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant),
                ],
              ).expanded(),
              if (trailing != null)
                trailing!
              else if (isSelected)
                UContainer(
                  width: 24,
                  height: 24,
                  radius: 999,
                  color: scheme.primary,
                  alignment: Alignment.center,
                  child: Icon(Icons.check_rounded, size: 15, color: scheme.onPrimary),
                ),
            ],
          ),
          if (pills.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: pills),
        ],
      ),
    );
  }
}
