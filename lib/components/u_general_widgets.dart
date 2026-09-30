import "dart:ui" show ImageFilter;

import "package:u/utilities.dart";

/// Card list row with a tinted icon, title, subtitle and arrow. `UListTile(icon: Icons.person, title: "Profile", onTap: open)`
class UListTile extends StatelessWidget {
  const UListTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.textColor,
    this.subtitle,
    this.trailingIcon = Icons.arrow_forward_ios,
    super.key,
  });

  /// Icon shown with it.
  final IconData icon;

  /// Icon at the end.
  final IconData trailingIcon;

  /// Title text.
  final String title;

  /// Second line of text.
  final String? subtitle;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Text color.
  final Color? textColor;

  /// Called when tapped.
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
        trailing: Icon(trailingIcon, color: Theme.of(context).disabledColor, size: 16),
      ),
    ),
  );
}

/// Icon in a tinted rounded square. `UIconBackground(Icons.wallet, color: Colors.teal)`
class UIconBackground extends StatelessWidget {
  const UIconBackground(
    this.icon, {
    required this.color,
    this.size = 42,
    this.backgroundColor,
    this.radius = 12,
    super.key,
  });

  /// Icon shown with it.
  final IconData icon;

  /// Main color (defaults to the theme).
  final Color color;

  /// Size in logical pixels.
  final double size;

  /// Background color.
  final Color? backgroundColor;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) => UContainer(
    width: size,
    height: size,
    alignment: Alignment.center,
    color: backgroundColor ?? color.withValues(alpha: 0.2),
    radius: radius,
    child: Icon(icon, color: color, size: size / 1.8),
  );
}

/// Image/icon asset in a tinted rounded square.
class UImageBackground extends StatelessWidget {
  const UImageBackground(this.asset, {required this.color, this.size = 42, super.key});

  /// Asset path.
  final String asset;

  /// Main color (defaults to the theme).
  final Color color;

  /// Size in logical pixels.
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

/// Frosted-glass card (blurs what is behind it). `UGlassCard(child: content)`
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

  /// The widget inside.
  final Widget child;

  /// Glass color (theme surface by default).
  final Color? tint;

  /// Blur strength.
  final double blur;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double opacity;

  /// Corner radius.
  final double borderRadius;

  /// Shadow softness.
  final double shadowBlur;

  /// Shadow darkness (0 = none).
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

/// Card with an icon, title and subtitle (page intro). `UHeaderCard(icon: Icons.info, title: "Hi", subtitle: "Welcome")`
class UHeaderCard extends StatelessWidget {
  const UHeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.iconColor,
  });

  /// Icon shown with it.
  final IconData icon;

  /// Title text.
  final String title;

  /// Second line of text.
  final String subtitle;

  /// Icon color.
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

/// "No data" message with optional icon, second line and action button. `UEmptyState(icon: Icons.inbox, title: "No orders yet", action: UButton(title: "Shop", onTap: shop))`
class UEmptyState extends StatelessWidget {
  const UEmptyState({super.key, this.title, this.message, this.icon, this.action});

  /// Title text.
  final String? title;

  /// Second line under the title.
  final String? message;

  /// Icon shown with it.
  final IconData? icon;

  /// Button under the text.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      spacing: 8,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) Icon(icon, size: 56, color: scheme.outline),
        UTextBodySmall(title ?? U.s.noData, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
        if (message != null) UTextLabelSmall(message!, color: scheme.outline, textAlign: TextAlign.center),
        if (action != null) action!.pOnly(top: 8),
      ],
    ).alignAtCenter();
  }
}

/// "Error loading data" text with a Try again button. `UErrorRetry(onTap: reload)`
class UErrorRetry extends StatelessWidget {
  const UErrorRetry({
    required this.onTap,
    super.key,
    this.title,
    this.buttonTitle,
  });

  /// Called when tapped.
  final VoidCallback onTap;

  /// Title text.
  final String? title;

  /// Button text.
  final String? buttonTitle;

  @override
  Widget build(BuildContext context) => UIconTextVertical(
    leading: UTextBodyMedium(title ?? U.s.errorLoadingData),
    trailing: UButton(title: buttonTitle ?? U.s.tryAgain, onTap: onTap),
  );
}

/// Small tinted label with optional icon (statuses, tags). `UPill("Paid", color: Colors.green, icon: Icons.check)`
class UPill extends StatelessWidget {
  const UPill(
    this.label, {
    super.key,
    this.color,
    this.icon,
  });

  /// Label text.
  final String label;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Icon shown with it.
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

/// Selectable card (plans, options) with pills and a check mark. `USelectionCard(title: "Gold", subtitle: "12 months", isSelected: plan == 1, onTap: () => plan = 1)`
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

  /// Title text.
  final String title;

  /// Second line of text.
  final String? subtitle;

  /// Small labels under the text.
  final List<Widget> pills;

  /// Widget at the end.
  final Widget? trailing;

  /// Shows the selected border and check.
  final bool isSelected;

  /// Greys it out and blocks taps.
  final bool isDisabled;

  /// Called when tapped.
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
                expanded: 1,
                spacing: 5,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextTitleLarge(title, color: scheme.onSurface),
                  if (subtitle != null) UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant),
                ],
              ),
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

/// Label on one side, value on the other. The building block of receipts, bills and detail sheets.
class UInfoRow extends StatelessWidget {
  const UInfoRow(
    this.label, {
    required this.value,
    super.key,
    this.valueColor,
    this.isStrong = false,
    this.trailing,
  });

  /// Label text.
  final String label;

  /// Current value.
  final String value;

  /// Color of the value text.
  final Color? valueColor;

  /// Bigger value text (totals).
  final bool isStrong;

  /// Widget at the end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      spacing: 12,
      children: <Widget>[
        Flexible(child: UTextBodyMedium(label, color: scheme.onSurfaceVariant)),
        if (trailing != null)
          Flexible(child: trailing!)
        else if (isStrong)
          Flexible(
            child: UTextTitleMedium(value, color: valueColor ?? scheme.onSurface, textAlign: TextAlign.end),
          )
        else
          Flexible(
            child: UTextBodyMedium(value, color: valueColor ?? scheme.onSurface, textAlign: TextAlign.end),
          ),
      ],
    );
  }
}

/// Compact metric tile — a caption over a large number, optionally with a unit or a secondary total.
class UStatTile extends StatelessWidget {
  const UStatTile({
    required this.caption,
    required this.value,
    super.key,
    this.unit,
    this.secondaryValue,
    this.valueColor,
    this.icon,
  });

  /// Small text above the number.
  final String caption;

  /// Current value.
  final String value;

  /// Unit after the number.
  final String? unit;

  /// Second number shown as "/ total".
  final String? secondaryValue;

  /// Color of the value text.
  final Color? valueColor;

  /// Icon shown with it.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      radius: 20,
      padding: const EdgeInsets.all(16),
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      child: UColumn(
        spacing: 6,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 6,
            children: <Widget>[
              if (icon != null) Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              Flexible(child: UTextLabelMedium(caption, color: scheme.onSurfaceVariant)),
            ],
          ),
          URow(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Flexible(child: UTextHeadlineMedium(value, color: valueColor ?? scheme.onSurface)),
              if (secondaryValue != null) UTextBodySmall("/ $secondaryValue", color: scheme.onSurfaceVariant),
              if (unit != null) UTextBodySmall(unit!, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large tappable action: an icon badge, a title and a one-line explanation. Sized for gloved thumbs on a POS.
class UActionTile extends StatelessWidget {
  const UActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.color,
  });

  /// Icon shown with it.
  final IconData icon;

  /// Title text.
  final String title;

  /// Second line of text.
  final String? subtitle;

  /// Main color (defaults to the theme).
  final Color? color;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tone = color ?? scheme.primary;
    return UContainer(
      radius: 20,
      padding: const EdgeInsets.all(16),
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      onTap: onTap,
      child: UColumn(
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UIconBackground(icon, color: tone, size: 44),
          UTextTitleLarge(title, color: scheme.onSurface),
          if (subtitle != null) UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Color of UAlertBanner: info, success, warning or danger.
enum UAlertTone { info, success, warning, danger }

/// Tinted callout used for pre-entry checks, offline notices and any other inline warning.
class UAlertBanner extends StatelessWidget {
  const UAlertBanner({
    required this.title,
    super.key,
    this.message,
    this.tone = UAlertTone.info,
    this.icon,
    this.actions = const <Widget>[],
  });

  /// Title text.
  final String title;

  /// Second line under the title.
  final String? message;

  /// Color/icon style.
  final UAlertTone tone;

  /// Icon shown with it.
  final IconData? icon;

  /// Action widgets/buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = switch (tone) {
      UAlertTone.success => scheme.tertiary,
      UAlertTone.warning => scheme.secondary,
      UAlertTone.danger => scheme.error,
      UAlertTone.info => scheme.primary,
    };
    final IconData toneIcon =
        icon ??
        switch (tone) {
          UAlertTone.success => Icons.check_circle_outline_rounded,
          UAlertTone.warning => Icons.warning_amber_rounded,
          UAlertTone.danger => Icons.cancel_outlined,
          UAlertTone.info => Icons.info_outline_rounded,
        };
    return UContainer(
      radius: 18,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.35)),
      child: UColumn(
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(toneIcon, color: color, size: 20),
              UColumn(
                expanded: 1,
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextTitleMedium(title, color: color),
                  if (message != null) UTextBodySmall(message!, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

/// Round profile picture with an initials fallback while loading or without a picture. `UAvatar(url: user.avatar, name: user.fullName)`
class UAvatar extends StatelessWidget {
  const UAvatar({super.key, this.url, this.name, this.size = 44, this.backgroundColor, this.onTap});

  /// Web address of the content.
  final String? url;

  /// Name.
  final String? name;

  /// Size in logical pixels.
  final double size;

  /// Background color.
  final Color? backgroundColor;

  /// Called when tapped.
  final VoidCallback? onTap;

  /// Up to two initials from [name]; "?" when empty. `UAvatar.initialsOf("Sina Mohammadzadeh")` → "SM"
  static String initialsOf(String? name) {
    final List<String> parts = (name ?? "").trim().split(RegExp(r"\s+")).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    return parts.take(2).map((String p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tone = backgroundColor ?? HSLColor.fromAHSL(1, (UEncryption.fnv1a32(name ?? "") % 360).toDouble(), 0.45, 0.45).toColor();
    final Widget initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: tone,
      child: Text(
        initialsOf(name),
        style: TextStyle(color: backgroundColor == null ? Colors.white : scheme.onPrimary, fontSize: size * 0.38, fontWeight: FontWeight.w600),
      ),
    );
    final Widget child = ClipOval(
      child: url == null || url!.isEmpty
          ? initials
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              frameBuilder: (BuildContext context, Widget image, int? frame, bool sync) => frame == null && !sync ? initials : image,
              errorBuilder: (BuildContext context, Object error, StackTrace? stack) => initials,
            ),
    );
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}

/// Search box that waits until typing stops before calling [onSearch], with a clear button. `USearchField(onSearch: (q) => controller.search(q))`
class USearchField extends StatefulWidget {
  const USearchField({required this.onSearch, super.key, this.hint, this.debounce = const Duration(milliseconds: 400), this.controller, this.autofocus = false, this.minLength = 0});

  /// Called with the query after typing stops or on submit.
  final void Function(String query) onSearch;

  /// Hint (localized "Search" by default).
  final String? hint;

  /// Wait after the last key.
  final Duration debounce;

  /// Controller to read or change it from code.
  final TextEditingController? controller;

  /// Focuses on start.
  final bool autofocus;

  /// Ignores shorter queries (except empty).
  final int minLength;

  @override
  State<USearchField> createState() => _USearchFieldState();
}

class _USearchFieldState extends State<USearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  late final UDebouncer _debouncer = UDebouncer(delay: widget.debounce);

  @override
  void dispose() {
    _debouncer.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    setState(() {});
    final String q = text.trim();
    if (q.isNotEmpty && q.length < widget.minLength) return;
    _debouncer.run(() => widget.onSearch(q));
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.search,
    onChanged: _changed,
    onSubmitted: (String q) {
      _debouncer.cancel();
      widget.onSearch(q.trim());
    },
    decoration: InputDecoration(
      hintText: widget.hint ?? U.s.search,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _changed("");
              },
            ),
    ),
  );
}

/// Text that copies itself (or [copyValue]) on tap and says "Copied". `UCopyText("IR12 3456 …", copyValue: iban)`
class UCopyText extends StatelessWidget {
  const UCopyText(this.text, {super.key, this.copyValue, this.style, this.showIcon = true});

  /// Text to show.
  final String text;

  /// What is copied (defaults to the shown text).
  final String? copyValue;

  /// Text style (defaults to the theme).
  final TextStyle? style;

  /// Shows a copy icon.
  final bool showIcon;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(6),
    onTap: () => UClipboard.set(copyValue ?? text, snackBar: true),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: <Widget>[
        Flexible(child: Text(text, style: style)),
        if (showIcon) Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
      ],
    ),
  );
}
