import "package:mobile_scanner/mobile_scanner.dart";
import "package:u/utilities.dart" hide CameraLensType;

enum UScannerHintPosition { top, bottom }

class UScanner extends StatefulWidget {
  const UScanner({
    this.onScan,
    this.onCapture,
    this.onBarcodes,
    this.onScanError,
    this.controller,
    this.autoStart = true,
    this.cameraResolution,
    this.lensType = CameraLensType.any,
    this.detectionSpeed = DetectionSpeed.normal,
    this.detectionTimeoutMs = 250,
    this.facing = CameraFacing.back,
    this.formats = const <BarcodeFormat>[],
    this.returnImage = false,
    this.torchEnabled = false,
    this.invertImage = false,
    this.autoZoom = false,
    this.initialZoom,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholderBuilder,
    this.overlayBuilder,
    this.scanWindow,
    this.restrictToScanWindow = false,
    this.scanWindowUpdateThreshold = 0.0,
    this.useAppLifecycleState = true,
    this.tapToFocus = false,
    this.singleScan = true,
    this.hapticOnScan = true,
    this.showOverlay = true,
    this.overlayColor,
    this.scanWindowSize = const Size(280, 280),
    this.borderColor,
    this.borderWidth = 3,
    this.borderRadius = 16,
    this.cornerLength = 32,
    this.showCorners = true,
    this.showFullBorder = false,
    this.showScanLine = true,
    this.scanLineColor,
    this.scanLineThickness = 2,
    this.scanLineDuration = const Duration(seconds: 2),
    this.hintText,
    this.showHint = true,
    this.hintTextStyle,
    this.hintPosition = UScannerHintPosition.bottom,
    this.hintGap = 20,
    this.hintPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.hintBackgroundColor,
    this.hintBorderRadius = 12,
    this.showControls = true,
    this.showTorchButton = true,
    this.showSwitchCameraButton = true,
    this.showGalleryButton = false,
    this.controlsAlignment = Alignment.bottomCenter,
    this.controlsSpacing = 24,
    this.controlsPadding = const EdgeInsets.only(bottom: 40),
    this.controlIconColor,
    this.controlActiveIconColor,
    this.controlBackgroundColor,
    this.controlButtonSize = 52,
    this.controlIconSize = 26,
    this.torchOnIcon = Icons.flash_on_rounded,
    this.torchOffIcon = Icons.flash_off_rounded,
    this.switchCameraIcon = Icons.cameraswitch_rounded,
    this.galleryIcon = Icons.photo_library_rounded,
    super.key,
  });

  /// Called with the raw value of the first detected barcode.
  final ValueChanged<String>? onScan;

  /// Called with the full [BarcodeCapture] for every detection.
  final ValueChanged<BarcodeCapture>? onCapture;

  /// Called with the raw list of [Barcode]s for every detection.
  final ValueChanged<List<Barcode>>? onBarcodes;

  /// Called when the scanner throws while decoding.
  final void Function(Object error, StackTrace stackTrace)? onScanError;

  /// External controller. When provided, the controller-configuration fields
  /// (facing, formats, torchEnabled, ...) are ignored in favor of this instance.
  final MobileScannerController? controller;

  final bool autoStart;
  final Size? cameraResolution;
  final CameraLensType lensType;
  final DetectionSpeed detectionSpeed;
  final int detectionTimeoutMs;
  final CameraFacing facing;
  final List<BarcodeFormat> formats;
  final bool returnImage;
  final bool torchEnabled;
  final bool invertImage;
  final bool autoZoom;
  final double? initialZoom;

  final BoxFit fit;
  final Widget Function(BuildContext, MobileScannerException)? errorBuilder;
  final WidgetBuilder? placeholderBuilder;
  final LayoutWidgetBuilder? overlayBuilder;

  /// Explicit detection window. Overrides [restrictToScanWindow].
  final Rect? scanWindow;

  /// When true (and [scanWindow] is null) the detection is limited to the
  /// centered [scanWindowSize] rectangle.
  final bool restrictToScanWindow;
  final double scanWindowUpdateThreshold;
  final bool useAppLifecycleState;
  final bool tapToFocus;

  /// Stop reporting after the first successful scan.
  final bool singleScan;

  /// Fire a haptic pulse when a code is scanned.
  final bool hapticOnScan;

  final bool showOverlay;
  final Color? overlayColor;
  final Size scanWindowSize;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double cornerLength;
  final bool showCorners;
  final bool showFullBorder;
  final bool showScanLine;
  final Color? scanLineColor;
  final double scanLineThickness;
  final Duration scanLineDuration;

  final String? hintText;
  final bool showHint;
  final TextStyle? hintTextStyle;
  final UScannerHintPosition hintPosition;
  final double hintGap;
  final EdgeInsets hintPadding;
  final Color? hintBackgroundColor;
  final double hintBorderRadius;

  final bool showControls;
  final bool showTorchButton;
  final bool showSwitchCameraButton;
  final bool showGalleryButton;
  final Alignment controlsAlignment;
  final double controlsSpacing;
  final EdgeInsets controlsPadding;
  final Color? controlIconColor;
  final Color? controlActiveIconColor;
  final Color? controlBackgroundColor;
  final double controlButtonSize;
  final double controlIconSize;
  final IconData torchOnIcon;
  final IconData torchOffIcon;
  final IconData switchCameraIcon;
  final IconData galleryIcon;

  @override
  State<UScanner> createState() => _UScannerState();
}

class _UScannerState extends State<UScanner> with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late bool _ownsController;
  AnimationController? _lineController;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        MobileScannerController(
          autoStart: widget.autoStart,
          cameraResolution: widget.cameraResolution,
          lensType: widget.lensType,
          detectionSpeed: widget.detectionSpeed,
          detectionTimeoutMs: widget.detectionTimeoutMs,
          facing: widget.facing,
          formats: widget.formats,
          returnImage: widget.returnImage,
          torchEnabled: widget.torchEnabled,
          invertImage: widget.invertImage,
          autoZoom: widget.autoZoom,
          initialZoom: widget.initialZoom,
        );
    if (widget.showScanLine) _lineController = AnimationController(vsync: this, duration: widget.scanLineDuration)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineController?.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (widget.singleScan && _handled) return;
    if (capture.barcodes.isEmpty) return;
    widget.onCapture?.call(capture);
    widget.onBarcodes?.call(capture.barcodes);
    final String? raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    if (widget.singleScan) _handled = true;
    if (widget.hapticOnScan) HapticFeedback.mediumImpact();
    widget.onScan?.call(raw);
  }

  Future<void> _scanFromGallery() async {
    final List<FileData> files = await UFile.showImagePicker(source: UImageSource.gallery);
    final String? path = files.isNotEmpty ? files.first.path : null;
    if (path == null) return;
    final BarcodeCapture? capture = await _controller.analyzeImage(path, formats: widget.formats);
    if (capture != null) _onDetect(capture);
  }

  Color get _controlIconColor => widget.controlIconColor ?? Theme.of(context).colorScheme.onSurface;

  Color get _controlBackground => widget.controlBackgroundColor ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.85);

  Widget _controlButton({required IconData icon, required VoidCallback onTap, String? tooltip, Color? color}) {
    final Widget button = UContainer(
      color: _controlBackground,
      shape: BoxShape.circle,
      width: widget.controlButtonSize,
      height: widget.controlButtonSize,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: widget.controlIconSize, color: color ?? _controlIconColor),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _buildControls() => ValueListenableBuilder<MobileScannerState>(
    valueListenable: _controller,
    builder: (BuildContext context, MobileScannerState state, Widget? child) {
      final bool torchOn = state.torchState == TorchState.on;
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: widget.controlsSpacing,
        children: <Widget>[
          if (widget.showGalleryButton) _controlButton(icon: widget.galleryIcon, tooltip: U.s.scanFromGallery, onTap: _scanFromGallery),
          if (widget.showTorchButton)
            _controlButton(
              icon: torchOn ? widget.torchOnIcon : widget.torchOffIcon,
              tooltip: U.s.flashlight,
              color: torchOn ? (widget.controlActiveIconColor ?? Theme.of(context).colorScheme.primary) : null,
              onTap: _controller.toggleTorch,
            ),
          if (widget.showSwitchCameraButton) _controlButton(icon: widget.switchCameraIcon, tooltip: U.s.switchCamera, onTap: _controller.switchCamera),
        ],
      );
    },
  );

  Widget _buildHint() => UContainer(
    color: widget.hintBackgroundColor ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
    radius: widget.hintBorderRadius,
    padding: widget.hintPadding,
    child: Text(
      widget.hintText ?? U.s.placeTheBarcodeInsideTheFrame,
      textAlign: TextAlign.center,
      style: widget.hintTextStyle ?? Theme.of(context).textTheme.bodySmall,
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final Rect window =
          widget.scanWindow ??
          Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: widget.scanWindowSize.width,
            height: widget.scanWindowSize.height,
          );
      final Rect? detectionWindow = widget.scanWindow ?? (widget.restrictToScanWindow ? window : null);
      final Color borderColor = widget.borderColor ?? Theme.of(context).colorScheme.primary;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            onDetectError: widget.onScanError ?? (Object error, StackTrace stackTrace) {},
            fit: widget.fit,
            errorBuilder: widget.errorBuilder,
            placeholderBuilder: widget.placeholderBuilder,
            overlayBuilder: widget.overlayBuilder,
            scanWindow: detectionWindow,
            scanWindowUpdateThreshold: widget.scanWindowUpdateThreshold,
            useAppLifecycleState: widget.useAppLifecycleState,
            tapToFocus: widget.tapToFocus,
          ),
          if (widget.showOverlay && widget.overlayBuilder == null)
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _UScannerOverlayPainter(
                window: window,
                overlayColor: widget.overlayColor ?? Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
                borderColor: borderColor,
                borderWidth: widget.borderWidth,
                borderRadius: widget.borderRadius,
                cornerLength: widget.cornerLength,
                showCorners: widget.showCorners,
                showFullBorder: widget.showFullBorder,
              ),
            ),
          if (widget.showScanLine && _lineController != null)
            AnimatedBuilder(
              animation: _lineController!,
              builder: (BuildContext context, Widget? child) {
                final double y = window.top + widget.borderWidth + (window.height - 2 * widget.borderWidth) * _lineController!.value;
                return Positioned(
                  left: window.left + widget.borderWidth,
                  top: y,
                  width: window.width - 2 * widget.borderWidth,
                  height: widget.scanLineThickness,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.scanLineColor ?? borderColor,
                      boxShadow: <BoxShadow>[BoxShadow(color: (widget.scanLineColor ?? borderColor).withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
                    ),
                  ),
                );
              },
            ),
          if (widget.showHint)
            Positioned(
              left: 24,
              right: 24,
              top: widget.hintPosition == UScannerHintPosition.top ? window.top - widget.hintGap - 44 : null,
              bottom: widget.hintPosition == UScannerHintPosition.bottom ? constraints.maxHeight - window.bottom - widget.hintGap - 44 : null,
              child: Align(child: _buildHint()),
            ),
          if (widget.showControls)
            Align(
              alignment: widget.controlsAlignment,
              child: Padding(padding: widget.controlsPadding, child: _buildControls()),
            ),
        ],
      );
    },
  );
}

/// Paints the dimmed area outside the scan [window] plus corner brackets or a
/// full rounded border.
class _UScannerOverlayPainter extends CustomPainter {
  _UScannerOverlayPainter({
    required this.window,
    required this.overlayColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.cornerLength,
    required this.showCorners,
    required this.showFullBorder,
  });

  final Rect window;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double cornerLength;
  final bool showCorners;
  final bool showFullBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect hole = RRect.fromRectAndRadius(window, Radius.circular(borderRadius));
    final Path background = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(hole),
    );
    canvas.drawPath(background, Paint()..color = overlayColor);

    final Paint border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    if (showFullBorder) {
      canvas.drawRRect(hole, border);
      return;
    }
    if (!showCorners) return;

    final double r = borderRadius;
    final double l = cornerLength;
    final Path path = Path()
      // top-left
      ..moveTo(window.left, window.top + r + l)
      ..lineTo(window.left, window.top + r)
      ..arcToPoint(Offset(window.left + r, window.top), radius: Radius.circular(r))
      ..lineTo(window.left + r + l, window.top)
      // top-right
      ..moveTo(window.right - r - l, window.top)
      ..lineTo(window.right - r, window.top)
      ..arcToPoint(Offset(window.right, window.top + r), radius: Radius.circular(r))
      ..lineTo(window.right, window.top + r + l)
      // bottom-right
      ..moveTo(window.right, window.bottom - r - l)
      ..lineTo(window.right, window.bottom - r)
      ..arcToPoint(Offset(window.right - r, window.bottom), radius: Radius.circular(r))
      ..lineTo(window.right - r - l, window.bottom)
      // bottom-left
      ..moveTo(window.left + r + l, window.bottom)
      ..lineTo(window.left + r, window.bottom)
      ..arcToPoint(Offset(window.left, window.bottom - r), radius: Radius.circular(r))
      ..lineTo(window.left, window.bottom - r - l);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_UScannerOverlayPainter oldDelegate) =>
      oldDelegate.window != window ||
      oldDelegate.overlayColor != overlayColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.showCorners != showCorners ||
      oldDelegate.showFullBorder != showFullBorder;
}

/// A ready-to-use full-screen scanner page wrapping [UScanner] in a [UScaffold].
///
/// By default it pops with the scanned string (`UNavigator.back<String>(value)`)
/// so it can be awaited with [UScannerPage.open]. Every [UScanner] option is
/// forwarded, plus page-level app bar / background customization.
class UScannerPage extends StatelessWidget {
  const UScannerPage({
    this.title,
    this.appBar,
    this.showAppBar = true,
    this.backgroundColor,
    this.autoPopOnScan = true,
    this.onScan,
    this.onCapture,
    this.onBarcodes,
    this.onScanError,
    this.controller,
    this.autoStart = true,
    this.cameraResolution,
    this.lensType = CameraLensType.any,
    this.detectionSpeed = DetectionSpeed.normal,
    this.detectionTimeoutMs = 250,
    this.facing = CameraFacing.back,
    this.formats = const <BarcodeFormat>[],
    this.returnImage = false,
    this.torchEnabled = false,
    this.invertImage = false,
    this.autoZoom = false,
    this.initialZoom,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholderBuilder,
    this.overlayBuilder,
    this.scanWindow,
    this.restrictToScanWindow = false,
    this.scanWindowUpdateThreshold = 0.0,
    this.useAppLifecycleState = true,
    this.tapToFocus = false,
    this.singleScan = true,
    this.hapticOnScan = true,
    this.showOverlay = true,
    this.overlayColor,
    this.scanWindowSize = const Size(280, 280),
    this.borderColor,
    this.borderWidth = 3,
    this.borderRadius = 16,
    this.cornerLength = 32,
    this.showCorners = true,
    this.showFullBorder = false,
    this.showScanLine = true,
    this.scanLineColor,
    this.scanLineThickness = 2,
    this.scanLineDuration = const Duration(seconds: 2),
    this.hintText,
    this.showHint = true,
    this.hintTextStyle,
    this.hintPosition = UScannerHintPosition.bottom,
    this.hintGap = 20,
    this.hintPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.hintBackgroundColor,
    this.hintBorderRadius = 12,
    this.showControls = true,
    this.showTorchButton = true,
    this.showSwitchCameraButton = true,
    this.showGalleryButton = false,
    this.controlsAlignment = Alignment.bottomCenter,
    this.controlsSpacing = 24,
    this.controlsPadding = const EdgeInsets.only(bottom: 40),
    this.controlIconColor,
    this.controlActiveIconColor,
    this.controlBackgroundColor,
    this.controlButtonSize = 52,
    this.controlIconSize = 26,
    this.torchOnIcon = Icons.flash_on_rounded,
    this.torchOffIcon = Icons.flash_off_rounded,
    this.switchCameraIcon = Icons.cameraswitch_rounded,
    this.galleryIcon = Icons.photo_library_rounded,
    super.key,
  });

  /// Push this page and await the scanned string (or null if dismissed).
  static Future<String?> open({
    String? title,
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
    String? hintText,
    bool showGalleryButton = false,
  }) => UNavigator.push<String>(UScannerPage(title: title, formats: formats, hintText: hintText, showGalleryButton: showGalleryButton));

  final String? title;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool autoPopOnScan;

  final ValueChanged<String>? onScan;
  final ValueChanged<BarcodeCapture>? onCapture;
  final ValueChanged<List<Barcode>>? onBarcodes;
  final void Function(Object error, StackTrace stackTrace)? onScanError;
  final MobileScannerController? controller;
  final bool autoStart;
  final Size? cameraResolution;
  final CameraLensType lensType;
  final DetectionSpeed detectionSpeed;
  final int detectionTimeoutMs;
  final CameraFacing facing;
  final List<BarcodeFormat> formats;
  final bool returnImage;
  final bool torchEnabled;
  final bool invertImage;
  final bool autoZoom;
  final double? initialZoom;
  final BoxFit fit;
  final Widget Function(BuildContext, MobileScannerException)? errorBuilder;
  final WidgetBuilder? placeholderBuilder;
  final LayoutWidgetBuilder? overlayBuilder;
  final Rect? scanWindow;
  final bool restrictToScanWindow;
  final double scanWindowUpdateThreshold;
  final bool useAppLifecycleState;
  final bool tapToFocus;
  final bool singleScan;
  final bool hapticOnScan;
  final bool showOverlay;
  final Color? overlayColor;
  final Size scanWindowSize;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double cornerLength;
  final bool showCorners;
  final bool showFullBorder;
  final bool showScanLine;
  final Color? scanLineColor;
  final double scanLineThickness;
  final Duration scanLineDuration;
  final String? hintText;
  final bool showHint;
  final TextStyle? hintTextStyle;
  final UScannerHintPosition hintPosition;
  final double hintGap;
  final EdgeInsets hintPadding;
  final Color? hintBackgroundColor;
  final double hintBorderRadius;
  final bool showControls;
  final bool showTorchButton;
  final bool showSwitchCameraButton;
  final bool showGalleryButton;
  final Alignment controlsAlignment;
  final double controlsSpacing;
  final EdgeInsets controlsPadding;
  final Color? controlIconColor;
  final Color? controlActiveIconColor;
  final Color? controlBackgroundColor;
  final double controlButtonSize;
  final double controlIconSize;
  final IconData torchOnIcon;
  final IconData torchOffIcon;
  final IconData switchCameraIcon;
  final IconData galleryIcon;

  @override
  Widget build(BuildContext context) => UScaffold(
    safeArea: false,
    extendBodyBehindAppBar: true,
    color: backgroundColor ?? Theme.of(context).colorScheme.scrim,
    appBar: showAppBar ? (appBar ?? AppBar(title: Text(title ?? U.s.scanBarcode), backgroundColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0), elevation: 0)) : null,
    body: UScanner(
      onScan: (String value) {
        onScan?.call(value);
        if (autoPopOnScan) UNavigator.back<String>(value);
      },
      onCapture: onCapture,
      onBarcodes: onBarcodes,
      onScanError: onScanError,
      controller: controller,
      autoStart: autoStart,
      cameraResolution: cameraResolution,
      lensType: lensType,
      detectionSpeed: detectionSpeed,
      detectionTimeoutMs: detectionTimeoutMs,
      facing: facing,
      formats: formats,
      returnImage: returnImage,
      torchEnabled: torchEnabled,
      invertImage: invertImage,
      autoZoom: autoZoom,
      initialZoom: initialZoom,
      fit: fit,
      errorBuilder: errorBuilder,
      placeholderBuilder: placeholderBuilder,
      overlayBuilder: overlayBuilder,
      scanWindow: scanWindow,
      restrictToScanWindow: restrictToScanWindow,
      scanWindowUpdateThreshold: scanWindowUpdateThreshold,
      useAppLifecycleState: useAppLifecycleState,
      tapToFocus: tapToFocus,
      singleScan: singleScan,
      hapticOnScan: hapticOnScan,
      showOverlay: showOverlay,
      overlayColor: overlayColor,
      scanWindowSize: scanWindowSize,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      cornerLength: cornerLength,
      showCorners: showCorners,
      showFullBorder: showFullBorder,
      showScanLine: showScanLine,
      scanLineColor: scanLineColor,
      scanLineThickness: scanLineThickness,
      scanLineDuration: scanLineDuration,
      hintText: hintText,
      showHint: showHint,
      hintTextStyle: hintTextStyle,
      hintPosition: hintPosition,
      hintGap: hintGap,
      hintPadding: hintPadding,
      hintBackgroundColor: hintBackgroundColor,
      hintBorderRadius: hintBorderRadius,
      showControls: showControls,
      showTorchButton: showTorchButton,
      showSwitchCameraButton: showSwitchCameraButton,
      showGalleryButton: showGalleryButton,
      controlsAlignment: controlsAlignment,
      controlsSpacing: controlsSpacing,
      controlsPadding: controlsPadding,
      controlIconColor: controlIconColor,
      controlActiveIconColor: controlActiveIconColor,
      controlBackgroundColor: controlBackgroundColor,
      controlButtonSize: controlButtonSize,
      controlIconSize: controlIconSize,
      torchOnIcon: torchOnIcon,
      torchOffIcon: torchOffIcon,
      switchCameraIcon: switchCameraIcon,
      galleryIcon: galleryIcon,
    ),
  );
}
