import "package:u/utilities.dart";

class UOtpField extends StatefulWidget {
  const UOtpField({
    this.controller,
    this.cursorColor,
    this.fillColor,
    this.activeColor,
    this.borderColor,
    this.length = 6,
    this.autoFocus = false,
    this.onChanged,
    this.onCompleted,
    this.textStyle,
    this.fieldWidth = 48,
    this.fieldHeight = 60,
    this.borderRadius = 8,
    this.borderWidth = 1,
    this.obscureText = false,
    this.obscuringCharacter = "•",
    this.keyboardType = TextInputType.number,
    this.showCursor = true,
    this.readOnly = false,
    this.decoration,
    this.autoDismissKeyboard = true,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    super.key,
  });

  final TextEditingController? controller;
  final int length;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final TextStyle? textStyle;
  final double fieldWidth;
  final double fieldHeight;
  final Color? cursorColor;
  final Color? fillColor;
  final Color? activeColor;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;
  final bool obscureText;
  final String obscuringCharacter;
  final TextInputType keyboardType;
  final bool showCursor;
  final bool readOnly;
  final InputDecoration? decoration;
  final bool autoDismissKeyboard;
  final MainAxisAlignment mainAxisAlignment;

  @override
  State<UOtpField> createState() => _UOtpFieldState();
}

class _UOtpFieldState extends State<UOtpField> {
  late TextEditingController controller;
  late List<FocusNode> _focusNodes;
  late List<FocusNode> _keyboardNodes;
  late List<TextEditingController> _controllers;
  late List<String> _otp;
  bool _ownsController = false;

  @override
  void initState() {
    _ownsController = widget.controller == null;
    controller = widget.controller ?? TextEditingController();
    super.initState();
    _initializeOtpFields();
  }

  void _initializeOtpFields() {
    _focusNodes = List<FocusNode>.generate(widget.length, (int index) => FocusNode());
    _keyboardNodes = List<FocusNode>.generate(widget.length, (int index) => FocusNode());
    _controllers = List<TextEditingController>.generate(widget.length, (int index) => TextEditingController());
    _otp = List<String>.generate(widget.length, (int index) => "");
    controller.addListener(_syncControllersWithMain);
  }

  void _syncControllersWithMain() {
    final String text = controller.text;
    for (int i = 0; i < widget.length; i++) {
      if (i < text.length) {
        _controllers[i].text = text[i];
      } else {
        _controllers[i].text = "";
      }
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    for (final FocusNode node in _keyboardNodes) {
      node.dispose();
    }
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    controller.removeListener(_syncControllersWithMain);
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      if (value.length == widget.length) {
        for (int i = 0; i < widget.length; i++) {
          _controllers[i].text = value[i];
          _otp[i] = value[i];
        }
        controller.text = value;
        _focusNodes.last.requestFocus();
      }
      return;
    }

    _otp[index] = value;
    controller.text = _otp.join();

    if (value.isNotEmpty && index < widget.length - 1) _focusNodes[index + 1].requestFocus();
    widget.onChanged?.call(controller.text);
    if (controller.text.length == widget.length && widget.onCompleted != null) widget.onCompleted!(controller.text);
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.backspace && _controllers[index].text.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
  }

  Color _getBorderColor(int index) {
    if (_focusNodes[index].hasFocus) {
      return widget.activeColor ?? Theme.of(context).colorScheme.primary;
    } else if (_controllers[index].text.isNotEmpty) {
      return (widget.activeColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.5);
    }
    return widget.borderColor ?? Theme.of(context).colorScheme.secondary;
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    builder: (FormFieldState<String> formFieldState) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: widget.mainAxisAlignment,
          children: List<Widget>.generate(
            widget.length,
            (int index) => SizedBox(
              width: widget.fieldWidth,
              height: widget.fieldHeight,
              child: KeyboardListener(
                focusNode: _keyboardNodes[index],
                onKeyEvent: (KeyEvent event) => _onKeyDown(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  autofocus: widget.autoFocus && index == 0,
                  textAlign: TextAlign.center,
                  style: widget.textStyle ?? Theme.of(context).textTheme.headlineSmall,
                  keyboardType: widget.keyboardType,
                  cursorColor: widget.cursorColor,
                  showCursor: widget.showCursor,
                  readOnly: widget.readOnly,
                  obscureText: widget.obscureText,
                  obscuringCharacter: widget.obscuringCharacter,
                  maxLength: 1,
                  decoration:
                      widget.decoration ??
                      InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: widget.fillColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide: BorderSide(
                            color: _getBorderColor(index),
                            width: widget.borderWidth,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide: BorderSide(color: widget.activeColor ?? Theme.of(context).colorScheme.primary, width: widget.borderWidth),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: widget.borderWidth),
                        ),
                      ),
                  onChanged: (String value) => _onChanged(index, value),
                ),
              ),
            ),
          ),
        ),
        if (formFieldState.hasError) UTextBodySmall(formFieldState.errorText!, color: Theme.of(context).colorScheme.error).pOnly(top: 8),
      ],
    ),
  ).ltr();
}
