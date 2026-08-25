import "dart:ui" as ui;

import "package:u/utilities.dart";

enum UCropShape { rectangle, circle }

enum _Handle { move, tl, tr, bl, br, t, b, l, r }

/// Aspect ratio option shown in the cropper toolbar. A `null` [ratio] means the
/// crop box can be resized freely.
class UCropAspectRatio {
  const UCropAspectRatio(this.label, this.ratio);

  final String label;
  final double? ratio;
}

/// A fully pure-Dart image cropper built on `dart:ui`. Unlike native plugins it
/// runs on every platform (mobile, web, Windows, macOS, Linux) and adds
/// rectangle/circle crop, aspect presets, 90° rotation, horizontal/vertical
/// flip and brightness/contrast/saturation adjustment. Pops a PNG [Uint8List].
class UImageCropper extends StatefulWidget {
  const UImageCropper({
    required this.bytes,
    super.key,
    this.title,
    this.shape = UCropShape.rectangle,
    this.aspectRatios,
    this.initialAspectRatio,
    this.allowRotate = true,
    this.allowFlip = true,
    this.allowAdjust = true,
    this.allowShapeToggle = false,
    this.maxWidth,
    this.maxHeight,
  });

  final Uint8List bytes;
  final String? title;
  final UCropShape shape;
  final List<UCropAspectRatio>? aspectRatios;
  final double? initialAspectRatio;
  final bool allowRotate;
  final bool allowFlip;
  final bool allowAdjust;
  final bool allowShapeToggle;
  final int? maxWidth;
  final int? maxHeight;

  @override
  State<UImageCropper> createState() => _UImageCropperState();
}

class _UImageCropperState extends State<UImageCropper> {
  ui.Image? _image;
  Rect _imageRect = Rect.zero;
  Rect _cropRect = Rect.zero;
  double? _aspect;
  late UCropShape _shape;
  bool _initialized = false;
  bool _busy = false;
  bool _showAdjust = false;
  _Handle? _dragHandle;

  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;

  static const double _minSize = 48;
  static const double _handleTolerance = 30;

  @override
  void initState() {
    super.initState();
    _shape = widget.shape;
    _aspect = widget.initialAspectRatio;
    _decode(widget.bytes);
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode(Uint8List bytes) async {
    final ui.Image decoded = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = decoded;
      _initialized = false;
    });
  }

  double get _originalRatio => _image == null ? 1 : _image!.width / _image!.height;

  List<UCropAspectRatio> get _ratios =>
      widget.aspectRatios ??
      <UCropAspectRatio>[
        UCropAspectRatio(U.s.free, null),
        UCropAspectRatio(U.s.original, _originalRatio),
        UCropAspectRatio(U.s.square, 1),
        const UCropAspectRatio("3:2", 3 / 2),
        const UCropAspectRatio("4:3", 4 / 3),
        const UCropAspectRatio("16:9", 16 / 9),
      ];

  Rect _fitImage(Size viewport) {
    if (_image == null) return Rect.zero;
    final double iw = _image!.width.toDouble();
    final double ih = _image!.height.toDouble();
    final double scale = min(viewport.width / iw, viewport.height / ih);
    final double w = iw * scale;
    final double h = ih * scale;
    return Rect.fromLTWH((viewport.width - w) / 2, (viewport.height - h) / 2, w, h);
  }

  Rect _aspectFit(double? aspect, Rect within) {
    if (aspect == null) return within;
    double w = within.width;
    double h = w / aspect;
    if (h > within.height) {
      h = within.height;
      w = h * aspect;
    }
    return Rect.fromCenter(center: within.center, width: w, height: h);
  }

  void _ensureInitialized(Size viewport) {
    _imageRect = _fitImage(viewport);
    if (!_initialized && _image != null && !_imageRect.isEmpty) {
      _cropRect = _aspectFit(_aspect, _imageRect);
      _initialized = true;
    } else {
      _cropRect = _clampToImage(_cropRect);
    }
  }

  Rect _clampToImage(Rect r) {
    double left = r.left;
    double top = r.top;
    final double width = min(r.width, _imageRect.width);
    final double height = min(r.height, _imageRect.height);
    if (left < _imageRect.left) left = _imageRect.left;
    if (top < _imageRect.top) top = _imageRect.top;
    if (left + width > _imageRect.right) left = _imageRect.right - width;
    if (top + height > _imageRect.bottom) top = _imageRect.bottom - height;
    return Rect.fromLTWH(left, top, width, height);
  }

  Map<_Handle, Offset> _handlePoints() {
    final Rect r = _cropRect;
    if (_aspect != null) {
      return <_Handle, Offset>{
        _Handle.tl: r.topLeft,
        _Handle.tr: r.topRight,
        _Handle.bl: r.bottomLeft,
        _Handle.br: r.bottomRight,
      };
    }
    return <_Handle, Offset>{
      _Handle.tl: r.topLeft,
      _Handle.tr: r.topRight,
      _Handle.bl: r.bottomLeft,
      _Handle.br: r.bottomRight,
      _Handle.t: r.topCenter,
      _Handle.b: r.bottomCenter,
      _Handle.l: r.centerLeft,
      _Handle.r: r.centerRight,
    };
  }

  _Handle? _hitTest(Offset p) {
    for (final MapEntry<_Handle, Offset> e in _handlePoints().entries) {
      if ((e.value - p).distance <= _handleTolerance) return e.key;
    }
    if (_cropRect.contains(p)) return _Handle.move;
    return null;
  }

  void _onPanStart(DragStartDetails d) => _dragHandle = _hitTest(d.localPosition);

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragHandle == null) return;
    if (_dragHandle == _Handle.move) {
      Rect r = _cropRect.shift(d.delta);
      double dx = 0;
      double dy = 0;
      if (r.left < _imageRect.left) dx = _imageRect.left - r.left;
      if (r.right > _imageRect.right) dx = _imageRect.right - r.right;
      if (r.top < _imageRect.top) dy = _imageRect.top - r.top;
      if (r.bottom > _imageRect.bottom) dy = _imageRect.bottom - r.bottom;
      r = r.shift(Offset(dx, dy));
      setState(() => _cropRect = r);
      return;
    }
    setState(() => _updateFromPointer(d.localPosition));
  }

  void _updateFromPointer(Offset raw) {
    final Offset p = Offset(
      raw.dx.clamp(_imageRect.left, _imageRect.right),
      raw.dy.clamp(_imageRect.top, _imageRect.bottom),
    );

    if (_aspect != null) {
      final Offset anchor = switch (_dragHandle) {
        _Handle.tl => _cropRect.bottomRight,
        _Handle.tr => _cropRect.bottomLeft,
        _Handle.bl => _cropRect.topRight,
        _ => _cropRect.topLeft,
      };
      _cropRect = _cornerAspect(anchor, p, _aspect!);
      return;
    }

    double l = _cropRect.left;
    double t = _cropRect.top;
    double r = _cropRect.right;
    double b = _cropRect.bottom;
    switch (_dragHandle!) {
      case _Handle.tl:
        l = min(p.dx, r - _minSize);
        t = min(p.dy, b - _minSize);
      case _Handle.tr:
        r = max(p.dx, l + _minSize);
        t = min(p.dy, b - _minSize);
      case _Handle.bl:
        l = min(p.dx, r - _minSize);
        b = max(p.dy, t + _minSize);
      case _Handle.br:
        r = max(p.dx, l + _minSize);
        b = max(p.dy, t + _minSize);
      case _Handle.t:
        t = min(p.dy, b - _minSize);
      case _Handle.b:
        b = max(p.dy, t + _minSize);
      case _Handle.l:
        l = min(p.dx, r - _minSize);
      case _Handle.r:
        r = max(p.dx, l + _minSize);
      case _Handle.move:
        break;
    }
    _cropRect = Rect.fromLTRB(l, t, r, b);
  }

  /// Largest rectangle of [aspect] anchored at [anchor] growing toward [pointer]
  /// while staying inside the image.
  Rect _cornerAspect(Offset anchor, Offset pointer, double aspect) {
    final bool towardRight = pointer.dx >= anchor.dx;
    final bool towardBottom = pointer.dy >= anchor.dy;
    final double boundW = towardRight ? _imageRect.right - anchor.dx : anchor.dx - _imageRect.left;
    final double boundH = towardBottom ? _imageRect.bottom - anchor.dy : anchor.dy - _imageRect.top;

    double w = min((pointer.dx - anchor.dx).abs(), boundW);
    double h = w / aspect;
    if (h > boundH) {
      h = boundH;
      w = h * aspect;
    }
    w = max(w, _minSize);
    h = max(h, _minSize / aspect);

    final double left = towardRight ? anchor.dx : anchor.dx - w;
    final double top = towardBottom ? anchor.dy : anchor.dy - h;
    return _clampToImage(Rect.fromLTWH(left, top, w, h));
  }

  void _selectAspect(double? aspect) {
    setState(() {
      _aspect = aspect;
      _cropRect = _aspectFit(aspect, _imageRect);
    });
  }

  Future<void> _transform(Future<ui.Image> Function(ui.Image src) op) async {
    if (_image == null) return;
    final ui.Image next = await op(_image!);
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = next;
      _initialized = false;
    });
  }

  Future<ui.Image> _rotate90(ui.Image src, {required bool clockwise}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double w = src.width.toDouble();
    final double h = src.height.toDouble();
    if (clockwise) {
      canvas.translate(h, 0);
      canvas.rotate(pi / 2);
    } else {
      canvas.translate(0, w);
      canvas.rotate(-pi / 2);
    }
    canvas.drawImage(src, Offset.zero, Paint()..filterQuality = FilterQuality.high);
    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(src.height, src.width);
  }

  Future<ui.Image> _flip(ui.Image src, {required bool horizontal}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    if (horizontal) {
      canvas.translate(src.width.toDouble(), 0);
      canvas.scale(-1, 1);
    } else {
      canvas.translate(0, src.height.toDouble());
      canvas.scale(1, -1);
    }
    canvas.drawImage(src, Offset.zero, Paint()..filterQuality = FilterQuality.high);
    return recorder.endRecording().toImage(src.width, src.height);
  }

  List<double>? _colorMatrix() {
    if (_brightness == 0 && _contrast == 1 && _saturation == 1) return null;
    return _matmul(_brightnessMatrix(_brightness), _matmul(_contrastMatrix(_contrast), _saturationMatrix(_saturation)));
  }

  ColorFilter? _colorFilter() {
    final List<double>? m = _colorMatrix();
    return m == null ? null : ColorFilter.matrix(m);
  }

  Future<Uint8List?> _crop() async {
    final ui.Image img = _image!;
    final double scale = img.width / _imageRect.width;
    Rect src = Rect.fromLTWH(
      (_cropRect.left - _imageRect.left) * scale,
      (_cropRect.top - _imageRect.top) * scale,
      _cropRect.width * scale,
      _cropRect.height * scale,
    );
    src = Rect.fromLTRB(
      src.left.clamp(0, img.width.toDouble()),
      src.top.clamp(0, img.height.toDouble()),
      src.right.clamp(0, img.width.toDouble()),
      src.bottom.clamp(0, img.height.toDouble()),
    );

    double outW = src.width;
    double outH = src.height;
    double factor = 1;
    if (widget.maxWidth != null && outW > widget.maxWidth!) factor = min(factor, widget.maxWidth! / outW);
    if (widget.maxHeight != null && outH > widget.maxHeight!) factor = min(factor, widget.maxHeight! / outH);
    outW *= factor;
    outH *= factor;
    final int ow = outW.round().clamp(1, 100000);
    final int oh = outH.round().clamp(1, 100000);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Rect dst = Rect.fromLTWH(0, 0, ow.toDouble(), oh.toDouble());
    if (_shape == UCropShape.circle) canvas.clipPath(Path()..addOval(dst));
    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..colorFilter = _colorFilter(),
    );
    final ui.Image out = await recorder.endRecording().toImage(ow, oh);
    final ByteData? data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _done() async {
    if (_image == null || _busy) return;
    setState(() => _busy = true);
    final Uint8List? result = await _crop();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _reset() {
    setState(() {
      _brightness = 0;
      _contrast = 1;
      _saturation = 1;
      _aspect = widget.initialAspectRatio;
      _shape = widget.shape;
    });
    _decode(widget.bytes);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.title ?? U.s.cropImage),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.reset, onPressed: _busy ? null : _reset),
          IconButton(icon: const Icon(Icons.check_rounded), tooltip: U.s.done, onPressed: _busy ? null : _done),
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      _ensureInitialized(Size(constraints.maxWidth, constraints.maxHeight));
                      return GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: (DragEndDetails _) => _dragHandle = null,
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _CropPainter(
                            image: _image!,
                            imageRect: _imageRect,
                            cropRect: _cropRect,
                            shape: _shape,
                            handles: _handlePoints().values.toList(),
                            colorFilter: _colorFilter(),
                            borderColor: scheme.onSurface,
                            handleColor: scheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _toolbar(scheme),
              ],
            ),
    );
  }

  Widget _toolbar(ColorScheme scheme) => Material(
    color: scheme.surface,
    elevation: 8,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                for (final UCropAspectRatio r in _ratios)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(r.label),
                      selected: _aspect == r.ratio,
                      onSelected: (_) => _selectAspect(r.ratio),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (widget.allowRotate) ...<Widget>[
                IconButton(
                  icon: const Icon(Icons.rotate_left_rounded),
                  tooltip: U.s.rotateLeft,
                  onPressed: () => _transform((ui.Image i) => _rotate90(i, clockwise: false)),
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right_rounded),
                  tooltip: U.s.rotateRight,
                  onPressed: () => _transform((ui.Image i) => _rotate90(i, clockwise: true)),
                ),
              ],
              if (widget.allowFlip) ...<Widget>[
                IconButton(
                  icon: const Icon(Icons.flip_rounded),
                  tooltip: U.s.flipHorizontal,
                  onPressed: () => _transform((ui.Image i) => _flip(i, horizontal: true)),
                ),
                IconButton(
                  icon: Transform.rotate(angle: pi / 2, child: const Icon(Icons.flip_rounded)),
                  tooltip: U.s.flipVertical,
                  onPressed: () => _transform((ui.Image i) => _flip(i, horizontal: false)),
                ),
              ],
              if (widget.allowShapeToggle)
                IconButton(
                  icon: Icon(_shape == UCropShape.circle ? Icons.crop_square_rounded : Icons.circle_outlined),
                  onPressed: () => setState(() => _shape = _shape == UCropShape.circle ? UCropShape.rectangle : UCropShape.circle),
                ),
              if (widget.allowAdjust)
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  color: _showAdjust ? scheme.primary : null,
                  onPressed: () => setState(() => _showAdjust = !_showAdjust),
                ),
            ],
          ),
          if (widget.allowAdjust && _showAdjust) ...<Widget>[
            _slider(U.s.brightness, _brightness, -1, 1, (double v) => setState(() => _brightness = v)),
            _slider(U.s.contrast, _contrast, 0, 2, (double v) => setState(() => _contrast = v)),
            _slider(U.s.saturation, _saturation, 0, 2, (double v) => setState(() => _saturation = v)),
          ],
        ],
      ),
    ),
  );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: <Widget>[
        SizedBox(width: 88, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    ),
  );
}

/// Multiplies two 4x5 colour matrices (treated as 5x5 with an implicit
/// `[0,0,0,0,1]` bottom row) — used to compose the adjustment filters.
List<double> _matmul(List<double> a, List<double> b) {
  final List<double> out = List<double>.filled(20, 0);
  for (int row = 0; row < 4; row++) {
    for (int col = 0; col < 5; col++) {
      double sum = 0;
      for (int k = 0; k < 4; k++) {
        sum += a[row * 5 + k] * b[k * 5 + col];
      }
      if (col == 4) sum += a[row * 5 + 4];
      out[row * 5 + col] = sum;
    }
  }
  return out;
}

List<double> _brightnessMatrix(double b) {
  final double o = b * 255;
  return <double>[1, 0, 0, 0, o, 0, 1, 0, 0, o, 0, 0, 1, 0, o, 0, 0, 0, 1, 0];
}

List<double> _contrastMatrix(double c) {
  final double t = 127.5 * (1 - c);
  return <double>[c, 0, 0, 0, t, 0, c, 0, 0, t, 0, 0, c, 0, t, 0, 0, 0, 1, 0];
}

List<double> _saturationMatrix(double s) {
  const double lr = 0.2126;
  const double lg = 0.7152;
  const double lb = 0.0722;
  final double sr = (1 - s) * lr;
  final double sg = (1 - s) * lg;
  final double sb = (1 - s) * lb;
  return <double>[
    sr + s, sg, sb, 0, 0, //
    sr, sg + s, sb, 0, 0, //
    sr, sg, sb + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.image,
    required this.imageRect,
    required this.cropRect,
    required this.shape,
    required this.handles,
    required this.colorFilter,
    required this.borderColor,
    required this.handleColor,
  });

  final ui.Image image;
  final Rect imageRect;
  final Rect cropRect;
  final UCropShape shape;
  final List<Offset> handles;
  final ColorFilter? colorFilter;
  final Color borderColor;
  final Color handleColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()
        ..filterQuality = FilterQuality.high
        ..colorFilter = colorFilter,
    );

    final Path scrim = Path()..addRect(Offset.zero & size);
    final Path hole = shape == UCropShape.circle ? (Path()..addOval(cropRect)) : (Path()..addRect(cropRect));
    canvas.drawPath(Path.combine(PathOperation.difference, scrim, hole), Paint()..color = Colors.black54);

    final Paint border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor;
    if (shape == UCropShape.circle) {
      canvas.drawOval(cropRect, border);
    } else {
      canvas.drawRect(cropRect, border);
      final Paint grid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = borderColor.withValues(alpha: 0.6);
      for (int i = 1; i < 3; i++) {
        final double dx = cropRect.left + cropRect.width * i / 3;
        final double dy = cropRect.top + cropRect.height * i / 3;
        canvas.drawLine(Offset(dx, cropRect.top), Offset(dx, cropRect.bottom), grid);
        canvas.drawLine(Offset(cropRect.left, dy), Offset(cropRect.right, dy), grid);
      }
    }

    final Paint fill = Paint()..color = handleColor;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    for (final Offset p in handles) {
      canvas.drawCircle(p, 7, fill);
      canvas.drawCircle(p, 7, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => true;
}
