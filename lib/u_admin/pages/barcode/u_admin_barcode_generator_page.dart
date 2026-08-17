import "package:u/utilities.dart";

class UAdminBarcodeGeneratorPage extends StatefulWidget {
  const UAdminBarcodeGeneratorPage({super.key});

  @override
  State<UAdminBarcodeGeneratorPage> createState() => _UAdminBarcodeGeneratorPageState();
}

class _UAdminBarcodeGeneratorPageState extends State<UAdminBarcodeGeneratorPage> {
  final TextEditingController _content = TextEditingController(text: "https://sinamn75.com");
  final WidgetToImageController _capture = WidgetToImageController();

  UBarcodeType _type = UBarcodeType.qrCode;
  Color _barColor = const Color(0xFF000000);
  Color _bgColor = const Color(0xFFFFFFFF);
  bool _useGradient = false;
  Color _gradientStart = const Color(0xFF6A11CB);
  Color _gradientEnd = const Color(0xFF2575FC);
  UBarcodeModuleShape _shape = UBarcodeModuleShape.square;
  double _cornerRadius = 0.3;
  double _quietZone = 8;
  bool _showValue = false;
  UErrorCorrectionLevel _ecc = UErrorCorrectionLevel.low;
  int _qrVersion = 0;
  Uint8List? _logo;
  double _logoRatio = 0.22;
  double _size = 280;
  bool _busy = false;

  Alignment _gradientBeginAlign = Alignment.centerLeft;
  Alignment _gradientEndAlign = Alignment.centerRight;

  Color _textColor = const Color(0xFF000000);
  double _textSize = 14;
  double _textSpacing = 8;
  bool _textBold = false;

  static const List<Color> _palette = <Color>[
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFF212121),
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFFF4511E),
    Color(0xFFFB8C00),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  bool get _is2d => _type == UBarcodeType.qrCode || _type == UBarcodeType.dataMatrix || _type == UBarcodeType.aztec || _type == UBarcodeType.pdf417;

  bool get _isQr => _type == UBarcodeType.qrCode;

  @override
  void initState() {
    super.initState();
    _content.addListener(_onChanged);
  }

  @override
  void dispose() {
    _content.removeListener(_onChanged);
    _content.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickLogo() async {
    final List<FileData> files = await UFile.showImagePicker(source: UImageSource.gallery, crop: const UCropOptions(aspectRatio: 1));
    if (!mounted || files.isEmpty || files.first.bytes == null) return;
    setState(() => _logo = files.first.bytes);
  }

  Future<void> _savePng() async {
    setState(() => _busy = true);
    final Uint8List? bytes = await _capture.capture();
    if (mounted) setState(() => _busy = false);
    if (bytes == null) return;
    await UShare.bytes(bytes: bytes, fileName: "barcode.png", mimeType: "image/png");
  }

  void _copySvg() {
    final String svg = UBarcode.toSvg(
      value: _content.text.trim(),
      type: _type,
      width: 400,
      height: _is2d ? 400 : 160,
      showValue: _showValue,
      errorCorrectionLevel: _ecc,
      qrCodeVersion: _qrVersion > 0 ? _qrVersion : null,
    );
    UClipboard.set(svg);
    UToast.snackBar(message: U.s.copiedToClipboard);
  }

  void _reset() => setState(() {
    _type = UBarcodeType.qrCode;
    _barColor = const Color(0xFF000000);
    _bgColor = const Color(0xFFFFFFFF);
    _useGradient = false;
    _shape = UBarcodeModuleShape.square;
    _cornerRadius = 0.3;
    _quietZone = 8;
    _showValue = false;
    _ecc = UErrorCorrectionLevel.low;
    _qrVersion = 0;
    _logo = null;
    _logoRatio = 0.22;
    _size = 280;
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return UScaffold(
      padding: const EdgeInsets.all(20),
      body: SingleChildScrollView(
        child: UColumn(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(cs),
            _preview(cs),
            _actions(cs),
            _contentCard(cs),
            _styleCard(cs),
            if (_is2d) _moduleCard(cs),
            if (_isQr) _qrCard(cs),
            if (!_is2d) _showValueCard(cs),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs) => URow(
    spacing: 14,
    children: <Widget>[
      Icon(Icons.qr_code_2_rounded, size: 34, color: cs.primary).container(padding: const EdgeInsets.all(12), backgroundColor: cs.primary.withValues(alpha: 0.12), radius: 16),
      UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextHeadlineSmall(U.s.barcodeqrGenerator, fontWeight: FontWeight.bold),
          UTextBodySmall(U.s.generateAndFullyCustomizeqrCodesAndBarcodesOfEveryKind, color: cs.onSurface.withValues(alpha: 0.6)),
        ],
      ).expanded(),
    ],
  );

  Widget _preview(ColorScheme cs) => Center(
    child: WidgetToImage(
      controller: _capture,
      child: UContainer(
        padding: const EdgeInsets.all(16),
        color: _bgColor,
        radius: 16,
        child: SizedBox(
          width: _size,
          height: _size,
          child: UBarcode(
            value: _content.text.trim().isEmpty ? " " : _content.text.trim(),
            type: _type,
            barColor: _barColor,
            backgroundColor: _bgColor,
            gradientColors: _useGradient ? <Color>[_gradientStart, _gradientEnd] : null,
            gradientBegin: _gradientBeginAlign,
            gradientEnd: _gradientEndAlign,
            moduleShape: _shape,
            cornerRadiusRatio: _cornerRadius,
            quietZone: _quietZone,
            showValue: _showValue,
            textSpacing: _textSpacing,
            textStyle: TextStyle(color: _textColor, fontSize: _textSize, fontWeight: _textBold ? FontWeight.bold : FontWeight.normal),
            errorCorrectionLevel: _ecc,
            qrCodeVersion: _qrVersion > 0 ? _qrVersion : null,
            logoBytes: _is2d ? _logo : null,
            logoSizeRatio: _logoRatio,
          ),
        ),
      ),
    ),
  ).container(padding: const EdgeInsets.all(16), backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4), radius: 20);

  Widget _actions(ColorScheme cs) => URow(
    spacing: 12,
    children: <Widget>[
      UButton(title: U.s.share, icon: const Icon(Icons.download_rounded), backgroundColor: cs.primary, foregroundColor: cs.onPrimary, isLoading: _busy, onTap: _savePng).expanded(),
      UButton(title: "SVG", icon: const Icon(Icons.code_rounded), backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurface, onTap: _copySvg).expanded(),
      UButton(title: U.s.reset, icon: const Icon(Icons.refresh_rounded), backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurface, onTap: _reset),
    ],
  );

  Widget _contentCard(ColorScheme cs) => _card(cs, Icons.edit_note_rounded, U.s.content, <Widget>[
    UTextField(controller: _content, hintText: U.s.content, lines: 3, contentPadding: const EdgeInsets.all(16)),
    UDropDownField<UBarcodeType>(
      initialValue: _type,
      labelText: U.s.barcodeType,
      items: UBarcodeType.values.map((UBarcodeType t) => DropdownMenuItem<UBarcodeType>(value: t, child: UTextBodyMedium(t.name))).toList(),
      onChanged: (UBarcodeType? t) => setState(() => _type = t ?? UBarcodeType.qrCode),
    ),
  ]);

  Widget _styleCard(ColorScheme cs) => _card(cs, Icons.palette_rounded, U.s.color, <Widget>[
    _swatchLabel(U.s.foreground, _barColor, (Color c) => setState(() => _barColor = c)),
    _swatchLabel(U.s.background, _bgColor, (Color c) => setState(() => _bgColor = c)),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: UTextBodyMedium(U.s.gradient),
      value: _useGradient,
      onChanged: (bool v) => setState(() => _useGradient = v),
    ),
    if (_useGradient) ...<Widget>[
      _swatchLabel("${U.s.gradient} 1", _gradientStart, (Color c) => setState(() => _gradientStart = c)),
      _swatchLabel("${U.s.gradient} 2", _gradientEnd, (Color c) => setState(() => _gradientEnd = c)),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _dirChip(cs, "→", Alignment.centerLeft, Alignment.centerRight),
          _dirChip(cs, "↓", Alignment.topCenter, Alignment.bottomCenter),
          _dirChip(cs, "↘", Alignment.topLeft, Alignment.bottomRight),
          _dirChip(cs, "↙", Alignment.topRight, Alignment.bottomLeft),
        ],
      ),
    ],
    _slider("${U.s.quietZone}: ${_quietZone.round()}", _quietZone, 0, 40, (double v) => setState(() => _quietZone = v)),
    _slider("${U.s.size}: ${_size.round()}", _size, 160, 360, (double v) => setState(() => _size = v)),
  ]);

  Widget _moduleCard(ColorScheme cs) => _card(cs, Icons.grid_view_rounded, U.s.moduleShape, <Widget>[
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: UBarcodeModuleShape.values.map((UBarcodeModuleShape s) => _chip(cs, s.name, _shape == s, () => setState(() => _shape = s))).toList(),
    ),
    if (_shape == UBarcodeModuleShape.rounded) _slider("${U.s.cornerRadius}: ${(_cornerRadius * 100).round()}%", _cornerRadius, 0, 0.5, (double v) => setState(() => _cornerRadius = v)),
    URow(
      spacing: 10,
      children: <Widget>[
        UButton(title: U.s.logo, icon: const Icon(Icons.image_rounded), type: UButtonType.outlined, onTap: _pickLogo).expanded(),
        if (_logo != null) UButton(title: U.s.remove, icon: const Icon(Icons.delete_outline_rounded), type: UButtonType.text, onTap: () => setState(() => _logo = null)),
      ],
    ),
    if (_logo != null) _slider("${U.s.logo}: ${(_logoRatio * 100).round()}%", _logoRatio, 0.1, 0.35, (double v) => setState(() => _logoRatio = v)),
  ]);

  Widget _qrCard(ColorScheme cs) => _card(cs, Icons.tune_rounded, "QR", <Widget>[
    UDropDownField<UErrorCorrectionLevel>(
      initialValue: _ecc,
      labelText: U.s.errorCorrection,
      items: UErrorCorrectionLevel.values.map((UErrorCorrectionLevel e) => DropdownMenuItem<UErrorCorrectionLevel>(value: e, child: UTextBodyMedium(e.name))).toList(),
      onChanged: (UErrorCorrectionLevel? e) => setState(() => _ecc = e ?? UErrorCorrectionLevel.low),
    ),
    UDropDownField<int>(
      initialValue: _qrVersion,
      labelText: U.s.version,
      items: <DropdownMenuItem<int>>[
        DropdownMenuItem<int>(value: 0, child: UTextBodyMedium(U.s.auto)),
        for (int v = 1; v <= 40; v++) DropdownMenuItem<int>(value: v, child: UTextBodyMedium("$v")),
      ],
      onChanged: (int? v) => setState(() => _qrVersion = v ?? 0),
    ),
  ]);

  Widget _showValueCard(ColorScheme cs) => _card(cs, Icons.text_fields_rounded, U.s.showValue, <Widget>[
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: UTextBodyMedium(U.s.showValue),
      value: _showValue,
      onChanged: (bool v) => setState(() => _showValue = v),
    ),
    if (_showValue) ...<Widget>[
      _swatchLabel(U.s.color, _textColor, (Color c) => setState(() => _textColor = c)),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: UTextBodyMedium(U.s.bold),
        value: _textBold,
        onChanged: (bool v) => setState(() => _textBold = v),
      ),
      _slider("${U.s.textSize}: ${_textSize.round()}", _textSize, 8, 32, (double v) => setState(() => _textSize = v)),
      _slider("${U.s.textSpacing}: ${_textSpacing.round()}", _textSpacing, 0, 40, (double v) => setState(() => _textSpacing = v)),
    ],
  ]);

  Widget _card(ColorScheme cs, IconData icon, String title, List<Widget> children) => UCard(
    child: UColumn(
      spacing: 14,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(spacing: 10, children: <Widget>[Icon(icon, color: cs.primary), UTextTitleMedium(title, fontWeight: FontWeight.bold)]),
        const Divider(height: 1),
        ...children,
      ],
    ).pAll(20),
  );

  Widget _swatchLabel(String label, Color selected, ValueChanged<Color> onSelect) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UTextLabelMedium(label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _palette.map((Color c) => _swatch(c, c.toARGB32() == selected.toARGB32(), () => onSelect(c))).toList(),
      ),
    ],
  );

  Widget _swatch(Color color, bool active, VoidCallback onTap) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, width: active ? 3 : 1),
    ),
    child: const SizedBox(width: 28, height: 28),
  ).onTap(onTap);

  Widget _chip(ColorScheme cs, String label, bool active, VoidCallback onTap) => UTextLabelLarge(label, color: active ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w600)
      .pSymmetric(horizontal: 14, vertical: 9)
      .container(backgroundColor: active ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5), radius: 12, borderColor: active ? cs.primary : cs.outlineVariant)
      .onTap(onTap);

  Widget _dirChip(ColorScheme cs, String label, Alignment begin, Alignment end) {
    final bool active = _gradientBeginAlign == begin && _gradientEndAlign == end;
    return _chip(cs, label, active, () => setState(() {
      _gradientBeginAlign = begin;
      _gradientEndAlign = end;
    }));
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UTextLabelMedium(label),
      Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
    ],
  );
}
