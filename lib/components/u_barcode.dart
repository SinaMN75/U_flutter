import "dart:ui" as ui;

import "package:u/utilities.dart";
import "package:u/src/barcode/u_barcode_engine.dart";

/// Every supported code: qrCode, dataMatrix, aztec, pdf417, code128, EAN/UPC, code39/93, ITF, Codabar, postal codes…
enum UBarcodeType {
  qrCode,
  dataMatrix,
  aztec,
  pdf417,
  code128,
  code128A,
  code128B,
  code128C,
  gs128,
  code39,
  code39Extended,
  code93,
  codabar,
  itf,
  itf14,
  itf16,
  ean13,
  ean8,
  ean5,
  ean2,
  upcA,
  upcE,
  isbn,
  telepen,
  rm4scc,
  postnet,
}

/// QR error correction: low, medium, quartile, high (higher survives damage/logos).
enum UErrorCorrectionLevel { low, medium, quartile, high }

/// Shape of QR dots: square, rounded or circle.
enum UBarcodeModuleShape { square, rounded, circle, dot }

BarcodeQRCorrectionLevel _mapEcc(UErrorCorrectionLevel level) => switch (level) {
  UErrorCorrectionLevel.low => BarcodeQRCorrectionLevel.low,
  UErrorCorrectionLevel.medium => BarcodeQRCorrectionLevel.medium,
  UErrorCorrectionLevel.quartile => BarcodeQRCorrectionLevel.quartile,
  UErrorCorrectionLevel.high => BarcodeQRCorrectionLevel.high,
};

Barcode _barcodeFor(UBarcodeType type, {int? qrVersion, UErrorCorrectionLevel ecc = UErrorCorrectionLevel.low}) => switch (type) {
  UBarcodeType.qrCode => Barcode.qrCode(typeNumber: qrVersion, errorCorrectLevel: _mapEcc(ecc)),
  UBarcodeType.dataMatrix => Barcode.dataMatrix(),
  UBarcodeType.aztec => Barcode.aztec(),
  UBarcodeType.pdf417 => Barcode.pdf417(),
  UBarcodeType.code128 => Barcode.code128(),
  UBarcodeType.code128A => Barcode.code128(useCode128B: false, useCode128C: false),
  UBarcodeType.code128B => Barcode.code128(useCode128A: false, useCode128C: false),
  UBarcodeType.code128C => Barcode.code128(useCode128A: false, useCode128B: false),
  UBarcodeType.gs128 => Barcode.gs128(),
  UBarcodeType.code39 || UBarcodeType.code39Extended => Barcode.code39(),
  UBarcodeType.code93 => Barcode.code93(),
  UBarcodeType.codabar => Barcode.codabar(),
  UBarcodeType.itf => Barcode.itf(),
  UBarcodeType.itf14 => Barcode.itf14(),
  UBarcodeType.itf16 => Barcode.itf16(),
  UBarcodeType.ean13 => Barcode.ean13(),
  UBarcodeType.ean8 => Barcode.ean8(),
  UBarcodeType.ean5 => Barcode.ean5(),
  UBarcodeType.ean2 => Barcode.ean2(),
  UBarcodeType.upcA => Barcode.upcA(),
  UBarcodeType.upcE => Barcode.upcE(),
  UBarcodeType.isbn => Barcode.isbn(),
  UBarcodeType.telepen => Barcode.telepen(),
  UBarcodeType.rm4scc => Barcode.rm4scc(),
  UBarcodeType.postnet => Barcode.postnet(),
};

/// Draws any barcode or QR code in pure Dart (all platforms), with colors, gradient, round dots and a center logo. `UBarcode(value: "https://x.com", type: UBarcodeType.qrCode, width: 200, height: 200)`
class UBarcode extends StatefulWidget {
  const UBarcode({
    required this.value,
    this.type = UBarcodeType.qrCode,
    this.barColor,
    this.backgroundColor,
    this.gradientColors,
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
    this.moduleShape = UBarcodeModuleShape.square,
    this.cornerRadiusRatio = 0.3,
    this.showValue = false,
    this.textSpacing = 8,
    this.textStyle,
    this.quietZone = 0,
    this.errorCorrectionLevel,
    this.qrCodeVersion,
    this.module,
    this.enableCheckSum,
    this.logoBytes,
    this.logoSizeRatio = 0.2,
    this.width,
    this.height,
    super.key,
  });

  /// Current value.
  final String value;

  /// Style variant.
  final UBarcodeType type;

  /// Bar/dot color.
  final Color? barColor;

  /// Background color.
  final Color? backgroundColor;

  /// Gradient for the bars.
  final List<Color>? gradientColors;

  /// Gradient start.
  final AlignmentGeometry gradientBegin;

  /// Gradient end.
  final AlignmentGeometry gradientEnd;

  /// Dot shape (QR/DataMatrix).
  final UBarcodeModuleShape moduleShape;

  /// Roundness of rounded dots, 0-0.5.
  final double cornerRadiusRatio;

  /// Writes the value under 1D barcodes.
  final bool showValue;

  /// Gap between bars and value text.
  final double textSpacing;

  /// Text style.
  final TextStyle? textStyle;

  /// Blank margin around the code (scanners need it).
  final double quietZone;

  /// QR error correction (use high with a logo).
  final UErrorCorrectionLevel? errorCorrectionLevel;

  /// QR size version 1-40 (null = smallest that fits).
  final int? qrCodeVersion;

  /// Module size hint.
  final int? module;

  /// Adds the check digit where the format has one.
  final bool? enableCheckSum;

  /// Logo image drawn in the middle of a QR.
  final Uint8List? logoBytes;

  /// Logo size as a share of the QR, e.g. 0.2.
  final double logoSizeRatio;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Renders a code to PNG bytes (to share or print). `await UBarcode.toPng(value: "123")`
  static Future<Uint8List?> toPng({
    required String value,
    UBarcodeType type = UBarcodeType.qrCode,
    double width = 512,
    double height = 512,
    double pixelRatio = 1,
    Color barColor = const Color(0xFF000000),
    Color background = const Color(0xFFFFFFFF),
    List<Color>? gradientColors,
    AlignmentGeometry gradientBegin = Alignment.centerLeft,
    AlignmentGeometry gradientEnd = Alignment.centerRight,
    UBarcodeModuleShape moduleShape = UBarcodeModuleShape.square,
    double cornerRadiusRatio = 0.3,
    bool showValue = false,
    double textSpacing = 8,
    double quietZone = 0,
    UErrorCorrectionLevel errorCorrectionLevel = UErrorCorrectionLevel.low,
    int? qrCodeVersion,
  }) async {
    final Barcode barcode = _barcodeFor(type, qrVersion: qrCodeVersion, ecc: errorCorrectionLevel);
    final _UBarcodePainter painter = _UBarcodePainter(
      barcode: barcode,
      data: value,
      drawText: showValue,
      foreground: barColor,
      background: background,
      gradient: gradientColors != null && gradientColors.length >= 2 ? LinearGradient(colors: gradientColors, begin: gradientBegin, end: gradientEnd) : null,
      moduleShape: moduleShape,
      cornerRadiusRatio: cornerRadiusRatio,
      quietZone: quietZone,
      textStyle: TextStyle(color: barColor, fontSize: 12),
      textPadding: textSpacing,
      is2D: barcode is Barcode2D,
      logo: null,
      logoRatio: 0,
    );
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    painter.paint(canvas, Size(width, height));
    final ui.Image image = await recorder.endRecording().toImage((width * pixelRatio).round(), (height * pixelRatio).round());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  /// Renders a code to SVG text.
  static String toSvg({
    required String value,
    UBarcodeType type = UBarcodeType.qrCode,
    double width = 200,
    double height = 80,
    bool showValue = false,
    UErrorCorrectionLevel errorCorrectionLevel = UErrorCorrectionLevel.low,
    int? qrCodeVersion,
  }) => _barcodeFor(type, qrVersion: qrCodeVersion, ecc: errorCorrectionLevel).toSvg(value, width: width, height: height, drawText: showValue);

  /// True when [value] can be encoded as [type] (length/characters/check digit). `UBarcode.isValid("5901234123457", UBarcodeType.ean13)`
  static bool isValid(String value, UBarcodeType type) => _barcodeFor(type).isValid(value);

  @override
  State<UBarcode> createState() => _UBarcodeState();
}

class _UBarcodeState extends State<UBarcode> {
  ui.Image? _logo;

  @override
  void initState() {
    super.initState();
    _decodeLogo();
  }

  @override
  void didUpdateWidget(covariant UBarcode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoBytes != widget.logoBytes) _decodeLogo();
  }

  @override
  void dispose() {
    _logo?.dispose();
    super.dispose();
  }

  Future<void> _decodeLogo() async {
    final Uint8List? bytes = widget.logoBytes;
    if (bytes == null) {
      if (_logo != null) setState(() => _logo = null);
      return;
    }
    final ui.Image decoded = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {
      _logo?.dispose();
      _logo = decoded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Barcode barcode = _barcodeFor(widget.type, qrVersion: widget.qrCodeVersion, ecc: widget.errorCorrectionLevel ?? UErrorCorrectionLevel.low);
    final Color foreground = widget.barColor ?? scheme.onSurface;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _UBarcodePainter(
          barcode: barcode,
          data: widget.value,
          drawText: widget.showValue,
          foreground: foreground,
          background: widget.backgroundColor,
          gradient: widget.gradientColors != null && widget.gradientColors!.length >= 2 ? LinearGradient(colors: widget.gradientColors!, begin: widget.gradientBegin, end: widget.gradientEnd) : null,
          moduleShape: widget.moduleShape,
          cornerRadiusRatio: widget.cornerRadiusRatio,
          quietZone: widget.quietZone,
          textStyle: widget.textStyle ?? TextStyle(color: foreground, fontSize: 12),
          textPadding: widget.textSpacing,
          is2D: barcode is Barcode2D,
          logo: _logo,
          logoRatio: widget.logoSizeRatio,
        ),
      ),
    );
  }
}

class _UBarcodePainter extends CustomPainter {
  _UBarcodePainter({
    required this.barcode,
    required this.data,
    required this.drawText,
    required this.foreground,
    required this.background,
    required this.gradient,
    required this.moduleShape,
    required this.cornerRadiusRatio,
    required this.quietZone,
    required this.textStyle,
    required this.textPadding,
    required this.is2D,
    required this.logo,
    required this.logoRatio,
  });

  final Barcode barcode;
  final String data;
  final bool drawText;
  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final UBarcodeModuleShape moduleShape;
  final double cornerRadiusRatio;
  final double quietZone;
  final TextStyle textStyle;
  final double textPadding;
  final bool is2D;
  final ui.Image? logo;
  final double logoRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) canvas.drawRect(Offset.zero & size, Paint()..color = background!);

    final double qz = quietZone.clamp(0, size.shortestSide / 3);
    final Rect area = Rect.fromLTWH(qz, qz, (size.width - 2 * qz).clamp(0, double.infinity), (size.height - 2 * qz).clamp(0, double.infinity));
    if (area.isEmpty) return;

    final Iterable<BarcodeElement> elements;
    try {
      elements = barcode.make(
        data,
        width: area.width,
        height: area.height,
        drawText: drawText,
        fontHeight: textStyle.fontSize,
        textPadding: textPadding,
      );
    } catch (e) {
      _paintError(canvas, size, e is BarcodeException ? e.message : e.toString());
      return;
    }

    final Paint barPaint = Paint()..isAntiAlias = moduleShape != UBarcodeModuleShape.square;
    if (gradient != null) {
      barPaint.shader = gradient!.createShader(area);
    } else {
      barPaint.color = foreground;
    }

    for (final BarcodeElement element in elements) {
      if (element is BarcodeBar) {
        if (!element.black) continue;
        final Rect r = Rect.fromLTWH(area.left + element.left, area.top + element.top, element.width, element.height);
        if (is2D && moduleShape != UBarcodeModuleShape.square) {
          _paintModule(canvas, r, barPaint);
        } else {
          canvas.drawRect(r, barPaint);
        }
      } else if (element is BarcodeText) {
        _paintText(canvas, area, element);
      }
    }

    if (logo != null && is2D) _paintLogo(canvas, area);
  }

  void _paintModule(Canvas canvas, Rect r, Paint paint) {
    switch (moduleShape) {
      case UBarcodeModuleShape.rounded:
        final double radius = r.shortestSide * cornerRadiusRatio;
        canvas.drawRRect(RRect.fromRectXY(r, radius, radius), paint);
      case UBarcodeModuleShape.circle:
        canvas.drawCircle(r.center, r.shortestSide / 2, paint);
      case UBarcodeModuleShape.dot:
        canvas.drawCircle(r.center, r.shortestSide / 2 * 0.82, paint);
      case UBarcodeModuleShape.square:
        canvas.drawRect(r, paint);
    }
  }

  void _paintText(Canvas canvas, Rect area, BarcodeText element) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: element.text, style: textStyle),
      textAlign: switch (element.align) {
        BarcodeTextAlign.left => TextAlign.left,
        BarcodeTextAlign.center => TextAlign.center,
        BarcodeTextAlign.right => TextAlign.right,
      },
      textDirection: TextDirection.ltr,
    )..layout(minWidth: element.width, maxWidth: element.width);
    tp.paint(canvas, Offset(area.left + element.left, area.top + element.top + (element.height - tp.height) / 2));
  }

  void _paintLogo(Canvas canvas, Rect area) {
    final double target = area.shortestSide * logoRatio.clamp(0.05, 0.35);
    final Rect dst = Rect.fromCenter(center: area.center, width: target, height: target);
    final Rect padded = dst.inflate(target * 0.12);
    canvas.drawRRect(RRect.fromRectXY(padded, target * 0.15, target * 0.15), Paint()..color = background ?? const Color(0xFFFFFFFF));
    final ui.Image image = logo!;
    final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.save();
    canvas.clipRRect(RRect.fromRectXY(dst, target * 0.1, target * 0.1));
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
  }

  void _paintError(Canvas canvas, Size size, String message) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(color: foreground, fontSize: 11),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 8);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _UBarcodePainter old) =>
      old.data != data ||
      old.barcode != barcode ||
      old.foreground != foreground ||
      old.background != background ||
      old.gradient != gradient ||
      old.moduleShape != moduleShape ||
      old.cornerRadiusRatio != cornerRadiusRatio ||
      old.quietZone != quietZone ||
      old.drawText != drawText ||
      old.textStyle != textStyle ||
      old.textPadding != textPadding ||
      old.logo != logo ||
      old.logoRatio != logoRatio;
}
