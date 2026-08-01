import "package:u/utilities.dart";

enum UButtonType { elevated, text, outlined, icon, fab, cupertino, custom }

enum UButtonIconPosition { leading, trailing }

class UButton extends StatefulWidget {
  const UButton({
    this.title,
    super.key,
    this.type = UButtonType.elevated,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.iconPosition = UButtonIconPosition.leading,
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
    this.borderRadius = 8,
    this.borderWidth = 1,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.elevation = 2,
    this.isLoading = false,
    this.enabled = true,
    this.tooltip,
    this.counter,
    this.counterDescription = "",
    this.counterOnCounting,
    this.counterResetCounterOnTap,
    this.heroTag,
  });

  final String? title;
  final UButtonType type;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? icon;
  final UButtonIconPosition iconPosition;
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? foregroundColor;
  final double borderRadius;
  final double borderWidth;
  final Color? borderColor;
  final EdgeInsets padding;
  final double elevation;
  final bool isLoading;
  final bool enabled;
  final String? tooltip;
  final int? counter;
  final String? counterDescription;
  final Function(int)? counterOnCounting;
  final bool? counterResetCounterOnTap;
  final String? heroTag;

  @override
  State<UButton> createState() => _UButtonState();
}

class _UButtonState extends State<UButton> {
  int counter = 0;

  // FIX: was `late Timer` which would throw in dispose when no counter was set; now nullable so it can be safely canceled.
  Timer? timer;
  String? title;
  VoidCallback? onTap;

  @override
  void initState() {
    title = widget.title;
    onTap = widget.onTap;
    if (widget.counter != null) startTimer();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer?.cancel();
    counter = widget.counter!;
    onTap = null;
    timer = Timer.periodic(const Duration(seconds: 1), (final Timer timer) {
      setState(() {
        counter--;
        title = "$counter ${widget.counterDescription}";
        if (widget.counterOnCounting != null) widget.counterOnCounting!(counter);
        if (counter <= 1) {
          title = widget.title;
          timer.cancel();
          onTap = widget.onTap;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = widget.isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: widget.foregroundColor ?? Colors.white),
          )
        : _buildContent();

    Widget button;

    switch (widget.type) {
      case UButtonType.elevated:
        button = ElevatedButton(
          onPressed: onTap != null && !widget.isLoading
              ? () {
                  onTap!();
                  if (widget.counterResetCounterOnTap == true) {
                    startTimer();
                  }
                }
              : null,
          onLongPress: widget.onLongPress != null || !widget.isLoading ? widget.onLongPress : null,
          style: _buildButtonStyle(),
          child: content,
        );
        break;
      case UButtonType.outlined:
        button = OutlinedButton(
          onPressed: onTap != null && !widget.isLoading
              ? () {
                  onTap!();
                  if (widget.counterResetCounterOnTap == true) {
                    startTimer();
                  }
                }
              : null,
          onLongPress: widget.onLongPress != null || !widget.isLoading ? widget.onLongPress : null,
          style: _buildButtonStyle(),
          child: content,
        );
        break;
      case UButtonType.text:
        button = TextButton(
          onPressed: onTap != null && !widget.isLoading
              ? () {
                  onTap!();
                  if (widget.counterResetCounterOnTap == true) {
                    startTimer();
                  }
                }
              : null,
          onLongPress: widget.onLongPress != null || !widget.isLoading ? widget.onLongPress : null,
          style: _buildButtonStyle(),
          child: content,
        );
        break;
      case UButtonType.icon:
        button = IconButton(
          onPressed: onTap != null && !widget.isLoading
              ? () {
                  onTap!();
                  if (widget.counterResetCounterOnTap == true) {
                    startTimer();
                  }
                }
              : null,
          icon: widget.icon ?? const SizedBox(),
          tooltip: widget.tooltip,
          color: widget.foregroundColor,
          splashRadius: widget.height != null ? widget.height! / 2 : 24,
        );
        break;
      case UButtonType.fab:
        if (widget.title == null)
          button = FloatingActionButton(
            heroTag: widget.heroTag,
            onPressed: onTap != null && !widget.isLoading
                ? () {
                    onTap!();
                    if (widget.counterResetCounterOnTap == true) startTimer();
                  }
                : null,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            child: widget.icon,
          );
        else
          button = FloatingActionButton.extended(
            heroTag: widget.heroTag,
            onPressed: onTap != null && !widget.isLoading
                ? () {
                    onTap!();
                    if (widget.counterResetCounterOnTap == true) startTimer();
                  }
                : null,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            icon: widget.icon,
            label: Text(widget.title!),
          );
        break;
      case UButtonType.cupertino:
        button = CupertinoButton(
          onPressed: onTap != null && !widget.isLoading
              ? () {
                  onTap!();
                  if (widget.counterResetCounterOnTap == true) {
                    startTimer();
                  }
                }
              : null,
          color: widget.backgroundColor,
          padding: widget.padding,
          disabledColor: widget.backgroundColor?.withValues(alpha: 0.5) ?? CupertinoColors.quaternarySystemFill,
          child: content,
        );
        break;
      case UButtonType.custom:
        button = InkWell(
          onTap: onTap != null && !widget.isLoading
              ? () {
                  onTap!();
                  if (widget.counterResetCounterOnTap == true) {
                    startTimer();
                  }
                }
              : null,
          onLongPress: widget.onLongPress != null || !widget.isLoading ? widget.onLongPress : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 46,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.gradient == null ? widget.backgroundColor : null,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.borderColor != null ? Border.all(color: widget.borderColor!, width: widget.borderWidth) : null,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        );
        break;
    }

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty && widget.type != UButtonType.icon) {
      return Tooltip(message: widget.tooltip, child: button);
    }

    return button;
  }

  Widget _buildContent() {
    if (widget.icon == null) return Text(title ?? "", textAlign: TextAlign.center, style: widget.textStyle);

    final List<Widget> children = <Widget>[];
    if (widget.iconPosition == UButtonIconPosition.leading) {
      children.add(widget.icon!);
      children.add(const SizedBox(width: 8));
    }
    children.add(
      Flexible(
        child: Text(title ?? "", textAlign: TextAlign.center, style: widget.textStyle),
      ),
    );
    if (widget.iconPosition == UButtonIconPosition.trailing) {
      children.add(const SizedBox(width: 8));
      children.add(widget.icon!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  ButtonStyle _buildButtonStyle() => ButtonStyle(
    textStyle: WidgetStateProperty.all(widget.textStyle),
    backgroundColor: widget.backgroundColor == null ? null : WidgetStateProperty.all(widget.backgroundColor),
    foregroundColor: widget.foregroundColor == null ? null : WidgetStateProperty.all(widget.foregroundColor),
    overlayColor: widget.backgroundColor == null ? WidgetStateProperty.all(widget.backgroundColor) : null,
    padding: WidgetStateProperty.all(widget.padding),
    minimumSize: WidgetStateProperty.all(Size(widget.minWidth ?? 0, widget.minHeight ?? 0)),
    maximumSize: WidgetStateProperty.all(Size(widget.maxWidth ?? double.infinity, widget.maxHeight ?? double.infinity)),
    fixedSize: WidgetStateProperty.all(Size(widget.width ?? double.infinity, widget.height ?? 46)),
    elevation: WidgetStateProperty.all(widget.type == UButtonType.elevated ? widget.elevation : 0),
    side: WidgetStateProperty.all(BorderSide(color: widget.borderColor ?? Colors.transparent, width: widget.borderWidth)),
  );
}

class UButtonSubmitCancel extends StatefulWidget {
  const UButtonSubmitCancel({
    required this.onSubmit,
    this.onCancel,
    this.submitTitle,
    this.cancelTitle,
    super.key,
  });

  final String? submitTitle;
  final String? cancelTitle;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;

  @override
  State<UButtonSubmitCancel> createState() => _UButtonSubmitCancelState();
}

class _UButtonSubmitCancelState extends State<UButtonSubmitCancel> {
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      UButton(
        title: widget.submitTitle ?? U.s.submit,
        onTap: widget.onSubmit,
      ).expanded(flex: 2),
      const SizedBox(width: 12),
      UButton(
        type: UButtonType.text,
        title: widget.cancelTitle ?? U.s.cancel,
        onTap: widget.onCancel ?? UNavigator.back,
      ).expanded(),
    ],
  );
}

class UPressable extends StatefulWidget {
  const UPressable({
    required this.child,
    required this.onTap,
    super.key,
    this.pressedScale = 0.9,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final Duration duration;

  @override
  State<UPressable> createState() => _UPressableState();
}

class _UPressableState extends State<UPressable> {
  bool _pressed = false;

  void _setPressed(final bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (final TapDownDetails _) => _setPressed(true),
    onTapUp: (final TapUpDetails _) => _setPressed(false),
    onTapCancel: () => _setPressed(false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
