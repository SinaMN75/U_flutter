import "package:u/utilities.dart";

/// Hue, saturation and brightness picker with a hex field. `UColorPicker(color: c, onChanged: (Color next) {})`
class UColorPicker extends StatefulWidget {
  const UColorPicker({
    super.key,
    this.color,
    this.onChanged,
    this.enabled = true,
    this.showOpacity = false,
  });

  /// Current color. Null starts at black.
  final Color? color;

  /// Called with the picked color.
  final ValueChanged<Color>? onChanged;

  /// False ignores drags and the hex field.
  final bool enabled;

  /// Adds an opacity slider and writes an eight-digit hex.
  final bool showOpacity;

  /// `#RRGGBB`, or `#AARRGGBB` when [alpha] is true.
  static String hex(Color color, {bool alpha = false}) {
    final int argb = color.toARGB32();
    final String digits = alpha ? argb.toRadixString(16).padLeft(8, "0") : (argb & 0xFFFFFF).toRadixString(16).padLeft(6, "0");
    return "#${digits.toUpperCase()}";
  }

  /// Reads `#RGB`, `#RRGGBB`, or `#AARRGGBB`. Eight digits are accepted only when [alpha] is true.
  static Color? tryParse(String raw, {bool alpha = false}) {
    final String body = raw.trim().replaceFirst("#", "");
    final int? value = int.tryParse(body, radix: 16);
    if (value == null) return null;
    if (body.length == 6) return Color(0xFF000000 | value);
    if (body.length == 3) {
      final int r = (value >> 8) & 0xF;
      final int g = (value >> 4) & 0xF;
      final int b = value & 0xF;
      return Color(0xFF000000 | (r << 20) | (r << 16) | (g << 12) | (g << 8) | (b << 4) | b);
    }
    if (alpha && body.length == 8) return Color(value);
    return null;
  }

  @override
  State<UColorPicker> createState() => _UColorPickerState();
}

class _UColorPickerState extends State<UColorPicker> {
  late HSVColor _hsv;
  late final TextEditingController _hex = TextEditingController();
  late final FocusNode _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hsv = _incoming(widget.color);
    _hex.text = UColorPicker.hex(_hsv.toColor(), alpha: widget.showOpacity);
  }

  @override
  void didUpdateWidget(UColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hexFocus.hasFocus) return;
    final HSVColor next = _incoming(widget.color);
    if (UColorPicker.hex(next.toColor(), alpha: widget.showOpacity) == UColorPicker.hex(_hsv.toColor(), alpha: widget.showOpacity)) return;
    _hsv = next;
    _hex.text = UColorPicker.hex(_hsv.toColor(), alpha: widget.showOpacity);
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  HSVColor _incoming(Color? color) {
    final HSVColor hsv = HSVColor.fromColor(color ?? Colors.black);
    return widget.showOpacity ? hsv : hsv.withAlpha(1);
  }

  void _apply(HSVColor next, {bool fromHex = false}) {
    final HSVColor value = widget.showOpacity ? next : next.withAlpha(1);
    setState(() => _hsv = value);
    if (!fromHex) _hex.text = UColorPicker.hex(value.toColor(), alpha: widget.showOpacity);
    widget.onChanged?.call(value.toColor());
  }

  void _plane(Offset local, Size size) {
    if (!widget.enabled || size.width <= 0 || size.height <= 0) return;
    final double saturation = (local.dx / size.width).clamp(0, 1);
    final double brightness = (1 - local.dy / size.height).clamp(0, 1);
    _apply(_hsv.withSaturation(saturation.toDouble()).withValue(brightness.toDouble()));
  }

  void _hue(Offset local, Size size) {
    if (!widget.enabled || size.width <= 0) return;
    _apply(_hsv.withHue(((local.dx / size.width).clamp(0, 1) * 360).toDouble()));
  }

  void _opacity(Offset local, Size size) {
    if (!widget.enabled || size.width <= 0) return;
    _apply(_hsv.withAlpha((local.dx / size.width).clamp(0, 1).toDouble()));
  }

  void _typeHex(String raw) {
    final Color? parsed = UColorPicker.tryParse(raw, alpha: widget.showOpacity);
    if (parsed == null) return;
    _apply(HSVColor.fromColor(parsed), fromHex: true);
  }

  @override
  Widget build(BuildContext context) {
    final Color picked = _hsv.toColor();
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _board(160, _plane, _SvPainter(_hsv.hue), Offset(_hsv.saturation, 1 - _hsv.value), picked),
        const SizedBox(height: 12),
        UTextBodySmall(U.s.hue),
        const SizedBox(height: 6),
        _board(18, _hue, const _HuePainter(), Offset(_hsv.hue / 360, 0.5), picked, radius: 9),
        if (widget.showOpacity) ...<Widget>[
          const SizedBox(height: 12),
          UTextBodySmall(U.s.opacity),
          const SizedBox(height: 6),
          _board(18, _opacity, _OpacityPainter(picked), Offset(_hsv.alpha, 0.5), picked, radius: 9),
        ],
        const SizedBox(height: 12),
        URow(
          children: <Widget>[
            UContainer(width: 44, height: 44, radius: 12, color: picked, border: Border.all(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(width: 12),
            UTextField(
              controller: _hex,
              focusNode: _hexFocus,
              labelText: U.s.hexColor,
              readOnly: !widget.enabled,
              maxLength: widget.showOpacity ? 9 : 7,
              formatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp("[#0-9a-fA-F]"))],
              onChanged: _typeHex,
              expanded: 1,
              validator: (String? value) => UColorPicker.tryParse(value ?? "", alpha: widget.showOpacity) == null ? U.s.enterAValidColor : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _board(double height, void Function(Offset local, Size size) onMove, CustomPainter painter, Offset unit, Color thumb, {double radius = 12}) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, height);
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            _AcceptPan: GestureRecognizerFactoryWithHandlers<_AcceptPan>(
              _AcceptPan.new,
              (_AcceptPan instance) {
                instance.onStart = (DragStartDetails details) => onMove(details.localPosition, size);
                instance.onUpdate = (DragUpdateDetails details) => onMove(details.localPosition, size);
              },
            ),
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: CustomPaint(
              painter: painter,
              foregroundPainter: _ThumbPainter(Offset(unit.dx * size.width, unit.dy * size.height), thumb),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    ),
  );
}

class _AcceptPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _SvPainter extends CustomPainter {
  const _SvPainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Color pure = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: <Color>[Colors.white, pure]).createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Colors.transparent, Colors.black]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SvPainter oldDelegate) => oldDelegate.hue != hue;
}

class _HuePainter extends CustomPainter {
  const _HuePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: <Color>[for (int stop = 0; stop <= 6; stop++) HSVColor.fromAHSV(1, stop * 60, 1, 1).toColor()]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) => false;
}

class _OpacityPainter extends CustomPainter {
  const _OpacityPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const double cell = 6;
    final Paint light = Paint()..color = const Color(0xFFFFFFFF);
    final Paint dark = Paint()..color = const Color(0xFFD0D0D0);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), ((x / cell).floor() + (y / cell).floor()).isEven ? light : dark);
      }
    }
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: <Color>[color.withValues(alpha: 0), color.withValues(alpha: 1)]).createShader(rect));
  }

  @override
  bool shouldRepaint(_OpacityPainter oldDelegate) => oldDelegate.color != color;
}

class _ThumbPainter extends CustomPainter {
  const _ThumbPainter(this.center, this.color);

  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(center, 7, Paint()..color = Colors.white);
    canvas.drawCircle(center, 5, Paint()..color = color);
    canvas.drawCircle(center, 7, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.black.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_ThumbPainter oldDelegate) => oldDelegate.center != center || oldDelegate.color != color;
}
