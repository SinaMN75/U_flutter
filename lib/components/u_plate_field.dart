import "package:u/utilities.dart";

const List<String> uPlateLetters = <String>["ب", "ج", "د", "س", "ص", "ط", "ق", "ک", "ل", "م", "ن", "و", "ه", "ی"];

class UPlateField extends StatefulWidget {
  const UPlateField({
    this.onPlateChange,
    super.key,
    this.initialPlate = "",
  });

  final String initialPlate;
  final ValueChanged<String>? onPlateChange;

  @override
  State<UPlateField> createState() => _UPlateFieldState();
}

class _UPlateFieldState extends State<UPlateField> {
  static const String _irIran = """
  <svg xmlns="http://www.w3.org/2000/svg" width="60.791" height="79.347" viewBox="0 0 60.791 79.347">
  <defs>
    <clipPath id="clip-path">
      <rect id="Rectangle_12" data-name="Rectangle 12" width="60.791" height="78.933" transform="translate(0 0)" fill="none"/>
    </clipPath>
  </defs>
  <g id="Group_27" data-name="Group 27" transform="translate(0 0)">
    <g id="Group_24" data-name="Group 24">
      <g id="Group_23" data-name="Group 23" clip-path="url(#clip-path)">
        <path id="Path_9" data-name="Path 9" d="M55.339,78.933H5.452A5.452,5.452,0,0,1,0,73.481V5.452A5.452,5.452,0,0,1,5.452,0H55.339a5.452,5.452,0,0,1,5.452,5.452V73.481a5.452,5.452,0,0,1-5.452,5.452" fill="#3e48ed"/>
      </g>
    </g>
    <text id="IR" transform="translate(5.966 50.983)" fill="#fff" font-size="19.252" font-family="YekanBakh-Regular, Yekan Bakh"><tspan x="0" y="0" letter-spacing="-0.01em">I</tspan><tspan y="0">R</tspan></text>
    <text id="IRAN" transform="translate(5.966 67.347)" fill="#fff" font-size="19.252" font-family="YekanBakh-Regular, Yekan Bakh"><tspan x="0" y="0" letter-spacing="-0.01em">I</tspan><tspan y="0" letter-spacing="-0.054em">R</tspan><tspan y="0" letter-spacing="-0.009em">A</tspan><tspan y="0">N</tspan></text>
    <g id="Group_26" data-name="Group 26">
      <g id="Group_25" data-name="Group 25" clip-path="url(#clip-path)">
        <rect id="Rectangle_13" data-name="Rectangle 13" width="38.785" height="7.87" transform="translate(7.42 11.792)" fill="#00af3a"/>
        <rect id="Rectangle_14" data-name="Rectangle 14" width="38.785" height="7.87" transform="translate(7.42 19.662)" fill="#fff"/>
        <rect id="Rectangle_15" data-name="Rectangle 15" width="38.785" height="7.87" transform="translate(7.42 27.532)" fill="#c40000"/>
      </g>
    </g>
  </g>
</svg>
  """;

  late TextEditingController digits1Controller;
  late TextEditingController digits3Controller;
  late TextEditingController provinceController;
  String letter = "";

  final FocusNode focus1 = FocusNode();
  final FocusNode focus3 = FocusNode();
  final FocusNode focusProv = FocusNode();
  final FocusNode letterFocusNode = FocusNode();

  final GlobalKey _letterButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  bool get _isReadOnly => widget.onPlateChange == null;

  ColorScheme get _scheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    String parsedDigits1 = "";
    String parsedDigits3 = "";
    String parsedProvince = "";
    String parsedLetter = "";

    if (widget.initialPlate.isNotEmpty) {
      for (int i = 0; i < widget.initialPlate.length && i < 2; i++) {
        if (widget.initialPlate[i].contains(RegExp("[0-9]"))) parsedDigits1 += widget.initialPlate[i];
      }
      for (int i = 0; i < widget.initialPlate.length; i++) {
        if (uPlateLetters.contains(widget.initialPlate[i])) {
          parsedLetter = widget.initialPlate[i];
          break;
        }
      }
      final int letterIndex = widget.initialPlate.indexOf(parsedLetter);
      if (letterIndex != -1 && letterIndex + 1 < widget.initialPlate.length) {
        for (int i = letterIndex + 1; i < widget.initialPlate.length && i < letterIndex + 4; i++) {
          if (widget.initialPlate[i].contains(RegExp("[0-9]"))) parsedDigits3 += widget.initialPlate[i];
        }
      }
      final List<String> digits = <String>[];
      for (int i = widget.initialPlate.length - 1; i >= 0 && digits.length < 2; i--) {
        if (widget.initialPlate[i].contains(RegExp("[0-9]"))) digits.insert(0, widget.initialPlate[i]);
      }
      parsedProvince = digits.join();
    }

    digits1Controller = TextEditingController(text: parsedDigits1);
    digits3Controller = TextEditingController(text: parsedDigits3);
    provinceController = TextEditingController(text: parsedProvince);
    letter = parsedLetter;

    if (!_isReadOnly) {
      digits1Controller.addListener(_onDigits1Changed);
      digits3Controller.addListener(_onDigits3Changed);
      provinceController.addListener(_onProvinceChanged);
    }
  }

  void _onDigits1Changed() {
    if (_isReadOnly) return;
    String value = digits1Controller.text.replaceAll(RegExp("[^0-9]"), "");
    if (value.length > 2) value = value.substring(0, 2);
    if (digits1Controller.text != value) {
      digits1Controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _updateFullPlate();
    if (value.length == 2 && letter.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _showLetterMenu());
  }

  void _onDigits3Changed() {
    if (_isReadOnly) return;
    String value = digits3Controller.text.replaceAll(RegExp("[^0-9]"), "");
    if (value.length > 3) value = value.substring(0, 3);
    if (digits3Controller.text != value) {
      digits3Controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _updateFullPlate();
    if (value.length == 3) focusProv.requestFocus();
  }

  void _onProvinceChanged() {
    if (_isReadOnly) return;
    String value = provinceController.text.replaceAll(RegExp("[^0-9]"), "");
    if (value.length > 2) value = value.substring(0, 2);
    if (provinceController.text != value) {
      provinceController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _updateFullPlate();
  }

  void _updateFullPlate() {
    if (_isReadOnly) return;
    widget.onPlateChange!.call("${digits1Controller.text}$letter${digits3Controller.text}${provinceController.text}");
  }

  void _showLetterMenu() {
    if (_isReadOnly) return;
    _overlayEntry?.remove();
    final RenderBox renderBox = _letterButtonKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: <Widget>[
          Positioned.fill(
            child: UContainer(
              onTap: _hideLetterMenu,
              child: const ColoredBox(color: Color(0x00000000)),
            ),
          ),
          Positioned(
            top: offset.dy + size.height,
            left: offset.dx,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: uPlateLetters
                          .map(
                            (String ch) => InkWell(
                              onTap: () {
                                setState(() => letter = ch);
                                _hideLetterMenu();
                                _updateFullPlate();
                                WidgetsBinding.instance.addPostFrameCallback((_) => focus3.requestFocus());
                              },
                              child: UContainer(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
                                child: Text(
                                  ch,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: scheme.onSurface),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideLetterMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    digits1Controller.dispose();
    digits3Controller.dispose();
    provinceController.dispose();
    focus1.dispose();
    focus3.dispose();
    focusProv.dispose();
    letterFocusNode.dispose();
    _hideLetterMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: <Widget>[
        _buildTextField(controller: provinceController, focusNode: focusProv, hint: "--", irPrefix: true, readOnly: _isReadOnly).expanded(flex: 3),
        const SizedBox(width: 4),
        _buildTextField(controller: digits3Controller, focusNode: focus3, hint: "---", readOnly: _isReadOnly).expanded(flex: 3),
        const SizedBox(width: 4),
        UContainer(
          expanded: 2,
          key: _letterButtonKey,
          onTap: _isReadOnly ? null : _showLetterMenu,
          height: 48,
          color: _isReadOnly ? _scheme.surfaceContainerHighest : null,
          radius: 8,
          border: Border.all(color: letter.isEmpty ? _scheme.onSurfaceVariant : _scheme.onSurface, width: 1.5),
          child: Center(
            child: Text(
              letter.isEmpty ? U.s.letter : letter,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: letter.isEmpty ? _scheme.onSurfaceVariant : (_isReadOnly ? _scheme.onSurfaceVariant : _scheme.onSurface)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _buildTextField(controller: digits1Controller, focusNode: focus1, hint: "--", readOnly: _isReadOnly).expanded(flex: 2),
        const SizedBox(width: 4),
        SizedBox(height: 52, child: SvgPicture.string(_irIran, fit: BoxFit.fill)).expanded(),
      ],
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    bool irPrefix = false,
    bool readOnly = false,
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    keyboardType: TextInputType.number,
    readOnly: readOnly,
    enableInteractiveSelection: !readOnly,
    decoration: InputDecoration(
      hintText: hint,
      prefix: irPrefix ? UTextLabelSmall(" ${U.s.iran} ") : null,
      hintStyle: TextStyle(fontSize: 18, color: _scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _scheme.onSurfaceVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _scheme.onSurfaceVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(width: 2, color: _scheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(),
      filled: readOnly,
      fillColor: readOnly ? _scheme.surfaceContainerHighest : null,
    ),
  );
}
