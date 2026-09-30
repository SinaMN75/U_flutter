import "package:flutter/cupertino.dart" show CupertinoActivityIndicator, CupertinoButton;
import "package:u/utilities.dart";

/// Button look: elevated, filled, filledTonal, text, outlined, icon, fab, cupertino, or custom.
enum UButtonType { elevated, filled, filledTonal, text, outlined, icon, fab, cupertino, custom }

/// Icon before (leading) or after (trailing) the title.
enum UButtonIconPosition { leading, trailing }

/// Preset height/padding: small, medium, large.
enum UButtonSize { small, medium, large }

/// Where the spinner shows while loading: replace the content, leading or trailing.
enum UButtonLoadingPosition { replace, leading, trailing }

double _uButtonHeight(UButtonSize size) => switch (size) {
  UButtonSize.small => 36,
  UButtonSize.medium => 46,
  UButtonSize.large => 56,
};

EdgeInsetsGeometry _uButtonPadding(UButtonSize size) => switch (size) {
  UButtonSize.small => const EdgeInsets.symmetric(horizontal: 12),
  UButtonSize.medium => const EdgeInsets.symmetric(horizontal: 16),
  UButtonSize.large => const EdgeInsets.symmetric(horizontal: 24),
};

double _uButtonIconSize(UButtonSize size) => switch (size) {
  UButtonSize.small => 16,
  UButtonSize.medium => 18,
  UButtonSize.large => 22,
};

/// Button with loading state, icon, sizes, full width, and a built-in "resend in 59s" countdown. `UButton(title: "Save", onTap: save, isLoading: saving)`
class UButton extends StatefulWidget {
  const UButton({
    this.title,
    super.key,
    this.type = UButtonType.elevated,
    this.size = UButtonSize.medium,
    this.onTap,
    this.onLongPress,
    this.child,
    this.icon,
    this.iconPosition = UButtonIconPosition.leading,
    this.iconGap = 8,
    this.iconSize,
    this.fullWidth = false,
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.textStyle,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.disabledOpacity = 0.45,
    this.borderRadius = 8,
    this.borderWidth = 1,
    this.borderColor,
    this.border,
    this.boxShadow,
    this.shape,
    this.padding,
    this.elevation = 2,
    this.splash = true,
    this.splashColor,
    this.highlightColor,
    this.pressedScale,
    this.isLoading = false,
    this.loadingWidget,
    this.loadingColor,
    this.loadingSize = 20,
    this.loadingStrokeWidth = 2,
    this.loadingPosition = UButtonLoadingPosition.replace,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.autofocus = false,
    this.focusNode,
    this.hapticFeedback = false,
    this.counter,
    this.counterDescription = "",
    this.counterOnCounting,
    this.counterResetCounterOnTap,
    this.onCountdownFinish,
    this.counterFormatter,
    this.heroTag,
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Title text.
  final String? title;

  /// Style variant.
  final UButtonType type;

  /// Size in logical pixels.
  final UButtonSize size;

  /// Called when tapped.
  final VoidCallback? onTap;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// The widget inside.
  final Widget? child;

  /// Icon shown with it.
  final Widget? icon;

  /// Icon before or after the title.
  final UButtonIconPosition iconPosition;

  /// Gap between icon and title.
  final double iconGap;

  /// Icon size.
  final double? iconSize;

  /// Stretches to the full width.
  final bool fullWidth;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Minimum width.
  final double? minWidth;

  /// Maximum width.
  final double? maxWidth;

  /// Minimum height.
  final double? minHeight;

  /// Maximum height.
  final double? maxHeight;

  /// Text style.
  final TextStyle? textStyle;

  /// Background color.
  final Color? backgroundColor;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Text/icon color.
  final Color? foregroundColor;

  /// Background while disabled (onTap null or counting down).
  final Color? disabledBackgroundColor;

  /// Text/icon color while disabled.
  final Color? disabledForegroundColor;

  /// Opacity while disabled.
  final double disabledOpacity;

  /// Corner radius.
  final double borderRadius;

  /// Border thickness.
  final double borderWidth;

  /// Border color.
  final Color? borderColor;

  /// Border around it.
  final BoxBorder? border;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Shape of the widget.
  final OutlinedBorder? shape;

  /// Space inside, around the content.
  final EdgeInsetsGeometry? padding;

  /// Shadow depth.
  final double elevation;

  /// Shows a Material ripple on tap.
  final bool splash;

  /// Ripple color.
  final Color? splashColor;

  /// Pressed highlight color.
  final Color? highlightColor;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double? pressedScale;

  /// Shows a loading state.
  final bool isLoading;

  /// Your own loading indicator.
  final Widget? loadingWidget;

  /// Spinner color.
  final Color? loadingColor;

  /// Spinner size.
  final double loadingSize;

  /// Spinner line width.
  final double loadingStrokeWidth;

  /// Where the spinner shows.
  final UButtonLoadingPosition loadingPosition;

  /// False disables interaction and greys it out.
  final bool enabled;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Label read by screen readers.
  final String? semanticLabel;

  /// Focuses the button on start (keyboard/TV).
  final bool autofocus;

  /// Focus node to control keyboard focus.
  final FocusNode? focusNode;

  /// Vibrates lightly on interaction (mobile).
  final bool hapticFeedback;

  /// Seconds of countdown before the button is enabled, e.g. 60 for "resend code". `UButton(title: "Resend", counter: 60, onTap: resend)`
  final int? counter;

  /// Text after the countdown, e.g. "until resend".
  final String? counterDescription;

  /// Called every second with the seconds left.
  final Function(int)? counterOnCounting;

  /// Starts the countdown again after each tap.
  final bool? counterResetCounterOnTap;

  /// Builds the countdown text from seconds left.
  final String Function(int secondsLeft)? counterFormatter;

  /// Called when the countdown reaches zero.
  final VoidCallback? onCountdownFinish;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// False hides it completely (takes no space).
  final bool visible;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  State<UButton> createState() => _UButtonState();
}

class _UButtonState extends State<UButton> {
  int _counter = 0;
  Timer? _timer;
  late String? _title;
  late VoidCallback? _onTap;

  bool get _counting => _timer != null;

  bool get _interactive => widget.enabled && !widget.isLoading && !_counting && widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _onTap = widget.onTap;
    if ((widget.counter ?? 0) > 0) _startTimer();
  }

  @override
  void didUpdateWidget(covariant UButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_counting && oldWidget.title != widget.title) _title = widget.title;
    if (!_counting && oldWidget.onTap != widget.onTap) _onTap = widget.onTap;
    if (widget.counter != null && widget.counter != oldWidget.counter && widget.counter! > 0) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _counter = widget.counter ?? 0;
    _onTap = null;
    _title = _counterTitle;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _counter--;
        if (_counter <= 0) {
          _title = widget.title;
          timer.cancel();
          _timer = null;
          _onTap = widget.onTap;
          widget.onCountdownFinish?.call();
        } else {
          _title = _counterTitle;
          widget.counterOnCounting?.call(_counter);
        }
      });
    });
  }

  String get _counterTitle => widget.counterFormatter?.call(_counter) ?? "${_formatCountdown(_counter)} ${widget.counterDescription ?? ""}".trim();

  static String _formatCountdown(int seconds) {
    final String minutes = (seconds % 3600 ~/ 60).toString().padLeft(2, "0");
    final String secs = (seconds % 60).toString().padLeft(2, "0");
    return seconds >= 3600 ? "${seconds ~/ 3600}:$minutes:$secs" : "$minutes:$secs";
  }

  void _handleTap() {
    if (widget.hapticFeedback) HapticFeedback.lightImpact();
    _onTap!();
    if (widget.counterResetCounterOnTap == true && (widget.counter ?? 0) > 0) setState(_startTimer);
  }

  VoidCallback? get _effectiveTap => _interactive ? _handleTap : null;

  VoidCallback? get _effectiveLongPress => (widget.enabled && !widget.isLoading) ? widget.onLongPress : null;

  EdgeInsetsGeometry get _resolvedPadding => widget.padding ?? _uButtonPadding(widget.size);

  Color _defaultForeground(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case UButtonType.elevated:
      case UButtonType.filled:
      case UButtonType.fab:
        return scheme.onPrimary;
      case UButtonType.filledTonal:
        return scheme.onSecondaryContainer;
      case UButtonType.outlined:
      case UButtonType.text:
      case UButtonType.icon:
      case UButtonType.cupertino:
      case UButtonType.custom:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button = switch (widget.type) {
      UButtonType.elevated => _buildMaterialButton(
        context,
        (ButtonStyle style, VoidCallback? onTap, Widget child) => ElevatedButton(
          onPressed: onTap,
          onLongPress: _effectiveLongPress,
          style: style,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          child: child,
        ),
      ),
      UButtonType.filled => _buildMaterialButton(
        context,
        (ButtonStyle style, VoidCallback? onTap, Widget child) => FilledButton(
          onPressed: onTap,
          onLongPress: _effectiveLongPress,
          style: style,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          child: child,
        ),
      ),
      UButtonType.filledTonal => _buildMaterialButton(
        context,
        (ButtonStyle style, VoidCallback? onTap, Widget child) => FilledButton.tonal(
          onPressed: onTap,
          onLongPress: _effectiveLongPress,
          style: style,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          child: child,
        ),
      ),
      UButtonType.outlined => _buildMaterialButton(
        context,
        (ButtonStyle style, VoidCallback? onTap, Widget child) => OutlinedButton(
          onPressed: onTap,
          onLongPress: _effectiveLongPress,
          style: style,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          child: child,
        ),
      ),
      UButtonType.text => _buildMaterialButton(
        context,
        (ButtonStyle style, VoidCallback? onTap, Widget child) => TextButton(
          onPressed: onTap,
          onLongPress: _effectiveLongPress,
          style: style,
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          child: child,
        ),
      ),
      UButtonType.icon => _buildIconButton(context),
      UButtonType.fab => _buildFab(context),
      UButtonType.cupertino => _buildCupertino(context),
      UButtonType.custom => _buildCustom(context),
    };

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty && widget.type != UButtonType.icon) {
      button = Tooltip(message: widget.tooltip, child: button);
    }

    final Widget result = Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: _interactive,
      child: button,
    );

    return uWrap(
      result,
      margin: widget.margin,
      visible: widget.visible,
      opacity: widget.opacity,
      fit: widget.fit,
      fitAlignment: widget.fitAlignment,
      scale: widget.scale,
      rotate: widget.rotate,
      translate: widget.translate,
      center: widget.center,
      safeArea: widget.safeArea,
      expanded: widget.expanded,
      flexible: widget.flexible,
      positioned: widget.positioned,
      left: widget.left,
      top: widget.top,
      right: widget.right,
      bottom: widget.bottom,
      positionedWidth: widget.positionedWidth,
      positionedHeight: widget.positionedHeight,
    );
  }

  /// Wraps ambient icon sizing around [_buildChild] without disturbing the
  /// foreground color cascade Material buttons already apply themselves.
  Widget _content(BuildContext context) => IconTheme.merge(
    data: IconThemeData(size: widget.iconSize ?? _uButtonIconSize(widget.size)),
    child: _buildChild(context),
  );

  Widget _buildMaterialButton(
    BuildContext context,
    Widget Function(ButtonStyle style, VoidCallback? onTap, Widget child) build,
  ) {
    final ButtonStyle style = _buildButtonStyle(context);
    final Widget button = build(style, _effectiveTap, _content(context));
    if (widget.width == null && !widget.fullWidth) return button;
    return SizedBox(width: widget.width ?? double.infinity, child: button);
  }

  ButtonStyle _buildButtonStyle(BuildContext context) {
    final Color? bg = widget.backgroundColor;
    final Color? fg = widget.foregroundColor;
    final double? exactHeight = widget.height;
    return ButtonStyle(
      textStyle: widget.textStyle == null ? null : WidgetStateProperty.all(widget.textStyle),
      backgroundColor: bg == null
          ? null
          : WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) return widget.disabledBackgroundColor ?? bg.withValues(alpha: widget.disabledOpacity);
              return bg;
            }),
      foregroundColor: fg == null
          ? null
          : WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) return widget.disabledForegroundColor ?? fg.withValues(alpha: widget.disabledOpacity);
              return fg;
            }),
      overlayColor: !widget.splash
          ? WidgetStateProperty.all(Colors.transparent)
          : (widget.splashColor == null && widget.highlightColor == null)
          ? null
          : WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) return widget.splashColor ?? widget.highlightColor;
              if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return widget.highlightColor ?? widget.splashColor;
              return null;
            }),
      padding: WidgetStateProperty.all(_resolvedPadding),
      // Only clamp width via minimumSize/maximumSize (never `fixedSize`,
      // which forces BOTH dimensions and previously made every button
      // request an infinite width whenever `height` was unset — a real
      // layout crash risk inside a Row/Wrap).
      minimumSize: WidgetStateProperty.all(Size(widget.minWidth ?? 0, exactHeight ?? widget.minHeight ?? _uButtonHeight(widget.size))),
      maximumSize: WidgetStateProperty.all(Size(widget.maxWidth ?? double.infinity, exactHeight ?? widget.maxHeight ?? double.infinity)),
      elevation: widget.type == UButtonType.elevated ? WidgetStateProperty.resolveWith((Set<WidgetState> states) => states.contains(WidgetState.disabled) ? 0 : widget.elevation) : null,
      side: widget.borderColor == null ? null : WidgetStateProperty.all(BorderSide(color: widget.borderColor!, width: widget.borderWidth)),
      shape: WidgetStateProperty.all(widget.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.borderRadius))),
    );
  }

  Widget _buildIconButton(BuildContext context) {
    final Color fg = widget.foregroundColor ?? _defaultForeground(context);
    return IconButton(
      onPressed: _effectiveTap,
      onLongPress: _effectiveLongPress,
      icon: widget.isLoading ? (widget.loadingWidget ?? _spinner(context)) : (widget.icon ?? const SizedBox.shrink()),
      tooltip: widget.tooltip,
      color: fg,
      disabledColor: widget.disabledForegroundColor ?? fg.withValues(alpha: widget.disabledOpacity),
      splashColor: widget.splash ? widget.splashColor : Colors.transparent,
      highlightColor: widget.splash ? widget.highlightColor : Colors.transparent,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      iconSize: widget.iconSize ?? _uButtonIconSize(widget.size) + 6,
      splashRadius: widget.height != null ? widget.height! / 2 : null,
    );
  }

  Widget _buildFab(BuildContext context) {
    final double fabIconSize = widget.iconSize ?? _uButtonIconSize(widget.size) + 6;
    final Widget? icon = widget.icon == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(size: fabIconSize),
            child: widget.icon!,
          );
    final Widget spinner = SizedBox(width: fabIconSize, height: fabIconSize, child: widget.loadingWidget ?? _spinner(context));

    final Widget fab = widget.title == null
        ? FloatingActionButton(
            heroTag: widget.heroTag,
            onPressed: _effectiveTap,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            splashColor: widget.splash ? widget.splashColor : Colors.transparent,
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            child: widget.isLoading ? spinner : icon,
          )
        : FloatingActionButton.extended(
            heroTag: widget.heroTag,
            onPressed: _effectiveTap,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            splashColor: widget.splash ? widget.splashColor : Colors.transparent,
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            icon: widget.isLoading ? null : icon,
            label: widget.isLoading ? spinner : Text(_title ?? "", style: widget.textStyle),
          );

    return widget.enabled ? fab : Opacity(opacity: widget.disabledOpacity, child: fab);
  }

  Widget _buildCupertino(BuildContext context) {
    final Color fg = widget.enabled
        ? (widget.foregroundColor ?? _defaultForeground(context))
        : (widget.disabledForegroundColor ?? (widget.foregroundColor ?? _defaultForeground(context)).withValues(alpha: widget.disabledOpacity));
    Widget button = CupertinoButton(
      onPressed: _effectiveTap,
      padding: _resolvedPadding,
      color: widget.backgroundColor,
      disabledColor: widget.disabledBackgroundColor ?? widget.backgroundColor?.withValues(alpha: widget.disabledOpacity) ?? const Color(0x00000000),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      child: DefaultTextStyle.merge(
        style: (widget.textStyle ?? const TextStyle()).copyWith(color: widget.textStyle?.color ?? fg),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: widget.iconSize ?? _uButtonIconSize(widget.size)),
          child: _buildChild(context),
        ),
      ),
    );
    if (widget.onLongPress != null) {
      button = GestureDetector(onLongPress: _effectiveLongPress, child: button);
    }
    if (widget.width != null || widget.fullWidth) {
      button = SizedBox(width: widget.width ?? double.infinity, child: button);
    }
    return button;
  }

  Widget _buildCustom(BuildContext context) {
    final Color fg = widget.foregroundColor ?? _defaultForeground(context);
    return UContainer(
      onTap: _effectiveTap,
      onLongPress: _effectiveLongPress,
      color: widget.gradient == null ? widget.backgroundColor : null,
      gradient: widget.gradient,
      border: widget.border ?? (widget.borderColor != null ? Border.all(color: widget.borderColor!, width: widget.borderWidth) : null),
      radius: widget.borderRadius,
      boxShadow: widget.boxShadow,
      width: widget.width ?? (widget.fullWidth ? double.infinity : null),
      height: widget.height,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      minHeight: widget.minHeight ?? _uButtonHeight(widget.size),
      maxHeight: widget.maxHeight,
      padding: _resolvedPadding,
      alignment: Alignment.center,
      splash: widget.splash,
      splashColor: widget.splashColor,
      highlightColor: widget.highlightColor,
      pressedScale: widget.pressedScale,
      opacity: widget.enabled ? null : widget.disabledOpacity,
      heroTag: widget.heroTag,
      child: DefaultTextStyle.merge(
        style: (widget.textStyle ?? const TextStyle()).copyWith(color: widget.textStyle?.color ?? fg),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: widget.iconSize ?? _uButtonIconSize(widget.size)),
          child: _buildChild(context),
        ),
      ),
    );
  }

  Widget _spinner(BuildContext context) {
    final Color color = widget.loadingColor ?? widget.foregroundColor ?? _defaultForeground(context);
    if (widget.type == UButtonType.cupertino) return CupertinoActivityIndicator(color: color, radius: widget.loadingSize / 2);
    return SizedBox(
      width: widget.loadingSize,
      height: widget.loadingSize,
      child: CircularProgressIndicator(strokeWidth: widget.loadingStrokeWidth, color: color),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (widget.isLoading && widget.loadingPosition == UButtonLoadingPosition.replace) {
      return widget.loadingWidget ?? _spinner(context);
    }

    final Widget label = widget.child ?? _buildLabelRow();
    if (!widget.isLoading) return label;

    final Widget spinner = widget.loadingWidget ?? _spinner(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.loadingPosition == UButtonLoadingPosition.leading) ...<Widget>[spinner, SizedBox(width: widget.iconGap)],
        Flexible(child: label),
        if (widget.loadingPosition == UButtonLoadingPosition.trailing) ...<Widget>[SizedBox(width: widget.iconGap), spinner],
      ],
    );
  }

  Widget _buildLabelRow() {
    if (widget.icon == null) return Text(_title ?? "", textAlign: TextAlign.center, style: widget.textStyle);

    final List<Widget> children = <Widget>[];
    if (widget.iconPosition == UButtonIconPosition.leading) {
      children.add(widget.icon!);
      children.add(SizedBox(width: widget.iconGap));
    }
    children.add(
      Flexible(
        child: Text(_title ?? "", textAlign: TextAlign.center, style: widget.textStyle),
      ),
    );
    if (widget.iconPosition == UButtonIconPosition.trailing) {
      children.add(SizedBox(width: widget.iconGap));
      children.add(widget.icon!);
    }

    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}

/// Submit + cancel buttons side by side (for forms and dialogs). `UButtonSubmitCancel(onSubmit: save)`
class UButtonSubmitCancel extends StatelessWidget {
  const UButtonSubmitCancel({
    required this.onSubmit,
    this.onCancel,
    this.submitTitle,
    this.cancelTitle,
    this.isLoading = false,
    this.enabled = true,
    super.key,
    this.onPress,
    this.onLongPress,
    this.cursor,
    this.onHover,
    this.margin,
    this.opacity,
    this.visible = true,
    this.tooltip,
    this.heroTag,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// Submit text (default "Submit").
  final String? submitTitle;

  /// Cancel text (default "Cancel").
  final String? cancelTitle;

  /// Called when submitted.
  final VoidCallback onSubmit;

  /// Called on cancel (default: go back).
  final VoidCallback? onCancel;

  /// Shows a loading state.
  final bool isLoading;

  /// False disables interaction and greys it out.
  final bool enabled;

  /// Called when tapped, with a press-down shrink effect.
  final VoidCallback? onPress;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Mouse cursor on hover (desktop, web).
  final MouseCursor? cursor;

  /// Called with true/false when a mouse enters/leaves (desktop, web).
  final ValueChanged<bool>? onHover;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => uWrap(
    Row(
      children: <Widget>[
        UButton(
          title: submitTitle ?? U.s.submit,
          onTap: onSubmit,
          isLoading: isLoading,
          enabled: enabled,
          expanded: 2,
        ),
        const SizedBox(width: 12),
        UButton(
          type: UButtonType.text,
          title: cancelTitle ?? U.s.cancel,
          onTap: onCancel ?? UNavigator.back,
          enabled: enabled && !isLoading,
          expanded: 1,
        ),
      ],
    ),
    onPress: onPress,
    onLongPress: onLongPress,
    cursor: cursor,
    onHover: onHover,
    margin: margin,
    opacity: opacity,
    visible: visible,
    tooltip: tooltip,
    heroTag: heroTag,
    fit: fit,
    fitAlignment: fitAlignment,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    scrollable: scrollable,
    scrollController: scrollController,
    textDirection: textDirection,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );
}

/// Makes any widget shrink a bit while pressed, then calls onTap. `UPressable(onTap: open, child: card)`
class UPressable extends StatefulWidget {
  const UPressable({
    required this.child,
    required this.onTap,
    super.key,
    this.pressedScale = 0.9,
    this.duration = const Duration(milliseconds: 120),
    this.enabled = true,
    this.margin,
    this.opacity,
    this.visible = true,
    this.tooltip,
    this.heroTag,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.scrollable,
    this.scrollController,
    this.textDirection,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  /// The widget inside.
  final Widget child;

  /// Called when tapped.
  final VoidCallback onTap;

  /// Scale while pressed, e.g. 0.95 for a subtle shrink.
  final double pressedScale;

  /// How long it lasts.
  final Duration duration;

  /// False disables interaction and greys it out.
  final bool enabled;

  /// Space outside, around the widget.
  final EdgeInsetsGeometry? margin;

  /// See-through amount, 0 (invisible) to 1 (solid).
  final double? opacity;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  /// Hero tag for a shared-element animation between pages.
  final String? heroTag;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  /// Alignment inside the box when it does not fill it.
  final AlignmentGeometry fitAlignment;

  /// Scales the painted widget (1 = normal size).
  final double? scale;

  /// Rotation in radians.
  final double? rotate;

  /// Moves the painted widget by this offset (layout unchanged).
  final Offset? translate;

  /// Centers it in the available space.
  final bool center;

  /// Keeps it out of the notch and system bars.
  final bool safeArea;

  /// Makes the content scroll when it does not fit.
  final Axis? scrollable;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Flex value to fill the remaining space in a Row/Column (null = off).
  final int? expanded;

  /// Flex value to shrink in a Row/Column when space is tight (null = off).
  final int? flexible;

  /// Wraps it in a Positioned (use inside a Stack) with top/left/right/bottom.
  final bool positioned;

  /// Distance from the left when [positioned] in a Stack.
  final double? left;

  /// Distance from the top when [positioned] in a Stack.
  final double? top;

  /// Distance from the right when [positioned] in a Stack.
  final double? right;

  /// Distance from the bottom when [positioned] in a Stack.
  final double? bottom;

  /// Width when [positioned].
  final double? positionedWidth;

  /// Height when [positioned].
  final double? positionedHeight;

  @override
  State<UPressable> createState() => _UPressableState();
}

class _UPressableState extends State<UPressable> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) => uWrap(
    GestureDetector(
      onTapDown: widget.enabled ? (TapDownDetails _) => _setPressed(true) : null,
      onTapUp: widget.enabled ? (TapUpDetails _) => _setPressed(false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    ),
    margin: widget.margin,
    opacity: widget.opacity,
    visible: widget.visible,
    tooltip: widget.tooltip,
    heroTag: widget.heroTag,
    fit: widget.fit,
    fitAlignment: widget.fitAlignment,
    scale: widget.scale,
    rotate: widget.rotate,
    translate: widget.translate,
    center: widget.center,
    safeArea: widget.safeArea,
    scrollable: widget.scrollable,
    scrollController: widget.scrollController,
    textDirection: widget.textDirection,
    expanded: widget.expanded,
    flexible: widget.flexible,
    positioned: widget.positioned,
    left: widget.left,
    top: widget.top,
    right: widget.right,
    bottom: widget.bottom,
    positionedWidth: widget.positionedWidth,
    positionedHeight: widget.positionedHeight,
  );
}
