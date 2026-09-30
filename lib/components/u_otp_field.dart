import "package:u/utilities.dart";

/// Keyboard for UOtpField: system keyboard or the built-in numeric pad.
enum UOtpKeyboardMode { system, external }

/// State of one OTP cell: empty, focused, filled, error.
enum UOtpCellState { empty, active, filled, error, disabled }

/// One-time-code boxes with paste, SMS autofill, obscuring and error state. `UOtpField(length: 6, onCompleted: verify)`
class UOtpField extends StatefulWidget {
  const UOtpField({
    super.key,
    this.controller,
    this.focusNode,
    this.length = 6,
    this.keyboardMode = UOtpKeyboardMode.system,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.validator,
    this.onSaved,
    this.autoFocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.obscuringCharacter = "•",
    this.autoDismissKeyboard = true,
    this.hapticFeedback = true,
    this.enableSmsAutoFill = true,
    this.showCursor = true,
    this.expand = true,
    this.fieldWidth = 48,
    this.fieldHeight = 60,
    this.spacing = 8,
    this.borderRadius = 8,
    this.borderWidth = 1,
    this.textStyle,
    this.fillColor,
    this.focusedFillColor,
    this.cursorColor,
    this.activeColor,
    this.borderColor,
    this.errorColor,
    this.textColor,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.animationDuration = const Duration(milliseconds: 150),
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.separatorBuilder,
    this.cellBuilder,
    this.filledBorderColor,
    this.activeBoxShadow,
    this.characterFormatter,
  });

  /// Controller to read or change it from code.
  final TextEditingController? controller;

  /// Focus node to control keyboard focus.
  final FocusNode? focusNode;

  /// Number of digits.
  final int length;

  /// System keyboard or built-in pad.
  final UOtpKeyboardMode keyboardMode;

  /// Called with the new value when the user changes it.
  final ValueChanged<String>? onChanged;

  /// Called when the input is complete.
  final ValueChanged<String>? onCompleted;

  /// Called when the keyboard's done is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Form validator; return an error text or null (see UValidators).
  final String? Function(String?)? validator;

  /// Form save callback.
  final Function(String? value)? onSaved;

  /// Focuses the first box on start.
  final bool autoFocus;

  /// False disables interaction and greys it out.
  final bool enabled;

  /// Shows the value without allowing edits.
  final bool readOnly;

  /// Hides the digits.
  final bool obscureText;

  /// Character shown instead of digits.
  final String obscuringCharacter;

  /// Closes the keyboard when complete.
  final bool autoDismissKeyboard;

  /// Vibrates lightly on interaction (mobile).
  final bool hapticFeedback;

  /// Offers the code from SMS (iOS/Android autofill).
  final bool enableSmsAutoFill;

  /// Shows a blinking cursor.
  final bool showCursor;

  /// Stretches boxes to the full width.
  final bool expand;

  /// Box width.
  final double fieldWidth;

  /// Box height.
  final double fieldHeight;

  /// Gap between items.
  final double spacing;

  /// Corner radius.
  final double borderRadius;

  /// Border thickness.
  final double borderWidth;

  /// Text style.
  final TextStyle? textStyle;

  /// Fill color.
  final Color? fillColor;

  /// Fill of the focused box.
  final Color? focusedFillColor;

  /// Cursor color.
  final Color? cursorColor;

  /// Border of the focused box.
  final Color? activeColor;

  /// Border color.
  final Color? borderColor;

  /// Border color on error.
  final Color? errorColor;

  /// Text color.
  final Color? textColor;

  /// How children are placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// Length of the animation.
  final Duration animationDuration;

  /// Keyboard type (numbers by default).
  final TextInputType keyboardType;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Widget between boxes (e.g. a dash after 3).
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Your own box widget.
  final Widget Function(BuildContext context, int index, String character, UOtpCellState state)? cellBuilder;

  /// Border of filled boxes.
  final Color? filledBorderColor;

  /// Shadow of the focused box.
  final List<BoxShadow>? activeBoxShadow;

  /// Formats each character (e.g. Persian digits).
  final String Function(String character)? characterFormatter;

  @override
  State<UOtpField> createState() => _UOtpFieldState();
}

class _UOtpFieldState extends State<UOtpField> with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _cursorController;
  late AnimationController _shakeController;
  FormFieldState<String>? _formState;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _hadError = false;
  String _lastValue = "";

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _lastValue = _controller.text;
    _controller.addListener(_onValueChanged);
    _focusNode.addListener(_onFocusChanged);
    _cursorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didUpdateWidget(covariant UOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onValueChanged);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController(text: _lastValue);
      _controller.addListener(_onValueChanged);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
    if (widget.length < oldWidget.length && _controller.text.length > widget.length) _setValue(_controller.text.substring(0, widget.length));
  }

  @override
  void dispose() {
    _controller.removeListener(_onValueChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    _cursorController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onValueChanged() {
    final String sanitized = _sanitize(_controller.text);
    if (sanitized != _controller.text) {
      _setValue(sanitized);
      return;
    }
    if (sanitized == _lastValue) {
      setState(() {});
      return;
    }
    _lastValue = sanitized;
    setState(() {});
    _formState?.didChange(sanitized);
    widget.onChanged?.call(sanitized);
    if (sanitized.length == widget.length) {
      if (widget.hapticFeedback) HapticFeedback.lightImpact();
      if (widget.autoDismissKeyboard) _focusNode.unfocus();
      widget.onCompleted?.call(sanitized);
    }
  }

  String _sanitize(String value) {
    String result = value.toLatinNumber();
    if (widget.keyboardType == TextInputType.number || widget.keyboardType == TextInputType.phone) result = result.replaceAll(RegExp(r"\D"), "");
    return result.length > widget.length ? result.substring(0, widget.length) : result;
  }

  void _setValue(String value) => _controller.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );

  bool get _isActive => widget.enabled && !widget.readOnly && (widget.keyboardMode == UOtpKeyboardMode.external || _focusNode.hasFocus);

  int get _cursorIndex => min(_controller.text.length, widget.length - 1);

  UOtpCellState _cellState(int index, bool hasError) {
    if (!widget.enabled) return UOtpCellState.disabled;
    if (hasError) return UOtpCellState.error;
    if (_isActive && index == _cursorIndex) return UOtpCellState.active;
    return index < _controller.text.length ? UOtpCellState.filled : UOtpCellState.empty;
  }

  Color _borderColor(UOtpCellState state, ColorScheme scheme) => switch (state) {
    UOtpCellState.disabled => scheme.onSurface.withValues(alpha: 0.2),
    UOtpCellState.error => widget.errorColor ?? scheme.error,
    UOtpCellState.active => widget.activeColor ?? scheme.primary,
    UOtpCellState.filled => widget.filledBorderColor ?? (widget.activeColor ?? scheme.primary).withValues(alpha: 0.5),
    UOtpCellState.empty => widget.borderColor ?? scheme.outlineVariant,
  };

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: _controller.text,
    validator: widget.validator,
    onSaved: widget.onSaved,
    enabled: widget.enabled,
    builder: (FormFieldState<String> formState) {
      _formState = formState;
      _scheduleShake(formState.hasError);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _shakeController,
            builder: (BuildContext context, Widget? child) => Transform.translate(
              offset: Offset(sin(_shakeController.value * pi * 5) * 8 * (1 - _shakeController.value), 0),
              child: child,
            ),
            child: Stack(
              children: <Widget>[
                _cells(context, formState.hasError),
                Positioned.fill(child: _editable()),
              ],
            ),
          ),
          if (formState.hasError) UTextBodySmall(formState.errorText!, color: widget.errorColor ?? Theme.of(context).colorScheme.error).pOnly(top: 8),
        ],
      ).ltr();
    },
  );

  void _scheduleShake(bool hasError) {
    if (hasError && !_hadError) {
      _hadError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _shakeController.forward(from: 0);
      });
    } else if (!hasError) {
      _hadError = false;
    }
  }

  Widget _cells(BuildContext context, bool hasError) => Row(
    mainAxisAlignment: widget.mainAxisAlignment,
    mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
    children: List<Widget>.generate(widget.length * 2 - 1, (int i) {
      if (i.isOdd) {
        final int index = (i - 1) ~/ 2;
        return widget.separatorBuilder?.call(context, index) ?? SizedBox(width: widget.spacing);
      }
      final int index = i ~/ 2;
      final Widget cell = _cell(context, index, hasError);
      return widget.expand ? Expanded(child: cell) : cell;
    }),
  );

  Widget _cell(BuildContext context, int index, bool hasError) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String value = _controller.text;
    final bool filled = index < value.length;
    final UOtpCellState state = _cellState(index, hasError);
    final String raw = filled ? value[index] : "";
    final String character = filled ? (widget.obscureText ? widget.obscuringCharacter : widget.characterFormatter?.call(raw) ?? raw) : "";

    if (widget.cellBuilder != null) return widget.cellBuilder!(context, index, character, state);

    return AnimatedContainer(
      duration: widget.animationDuration,
      width: widget.expand ? null : widget.fieldWidth,
      height: widget.fieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == UOtpCellState.active ? widget.focusedFillColor ?? widget.fillColor : widget.fillColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: _borderColor(state, scheme), width: state == UOtpCellState.active ? widget.borderWidth + 1 : widget.borderWidth),
        boxShadow: state == UOtpCellState.active ? widget.activeBoxShadow : null,
      ),
      child: filled
          ? Text(
              character,
              style: widget.textStyle ?? Theme.of(context).textTheme.headlineSmall?.copyWith(color: widget.textColor ?? scheme.onSurface),
            )
          : state == UOtpCellState.active && widget.showCursor
          ? FadeTransition(
              opacity: _cursorController,
              child: UContainer(
                width: 2,
                height: widget.fieldHeight * 0.4,
                color: widget.cursorColor ?? scheme.primary,
                radius: 1,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _editable() => Opacity(
    opacity: 0,
    child: TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autoFocus && widget.keyboardMode == UOtpKeyboardMode.system,
      readOnly: widget.readOnly || widget.keyboardMode == UOtpKeyboardMode.external,
      canRequestFocus: widget.enabled && !widget.readOnly && widget.keyboardMode == UOtpKeyboardMode.system,
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.done,
      autofillHints: widget.enableSmsAutoFill ? const <String>[AutofillHints.oneTimeCode] : null,
      inputFormatters:
          widget.inputFormatters ??
          <TextInputFormatter>[
            LengthLimitingTextInputFormatter(widget.length),
            if (widget.keyboardType == TextInputType.number || widget.keyboardType == TextInputType.phone) FilteringTextInputFormatter.digitsOnly,
          ],
      showCursor: false,
      enableInteractiveSelection: true,
      style: const TextStyle(height: 1),
      decoration: const InputDecoration(counterText: "", border: InputBorder.none, contentPadding: EdgeInsets.zero),
      onTap: () => _setValue(_controller.text),
      onSubmitted: widget.onSubmitted,
    ),
  );
}
