import "package:u/utilities.dart";

// =============================================================================
// u_scanner — barcode / QR scanning UI of the `u` plugin.
//
// Built on [UCameraController] and the bundled Dart decode engine, so it reads
// the same symbologies on all six platforms with no native decoder and no
// downloadable model. Every visual element is configurable.
// =============================================================================

enum UScannerHintPosition { top, bottom }

/// How aggressively frames are decoded. Slower settings cost less battery.
enum UScanSpeed { unrestricted, normal, slow }

extension UScanSpeedX on UScanSpeed {
  Duration get interval {
    switch (this) {
      case UScanSpeed.unrestricted:
        return const Duration(milliseconds: 40);
      case UScanSpeed.normal:
        return const Duration(milliseconds: 120);
      case UScanSpeed.slow:
        return const Duration(milliseconds: 400);
    }
  }

  double get maxFps {
    switch (this) {
      case UScanSpeed.unrestricted:
        return 24;
      case UScanSpeed.normal:
        return 12;
      case UScanSpeed.slow:
        return 5;
    }
  }
}

class UScanner extends StatefulWidget {
  const UScanner({
    this.onScan,
    this.onCodes,
    this.onScanError,
    this.controller,
    this.autoStart = true,
    this.facing = UCameraFacing.back,
    this.resolution = UCameraResolution.high,
    this.lensType,
    this.speed = UScanSpeed.normal,
    this.dedupeWindow = const Duration(milliseconds: 1500),
    this.formats = const <UCodeFormat>[],
    this.engine = UScanEngine.auto,
    this.torchEnabled = false,
    this.tryInvert = false,
    this.autoZoom = false,
    this.initialZoom,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholderBuilder,
    this.overlayBuilder,
    this.scanWindow,
    this.restrictToScanWindow = true,
    this.useAppLifecycleState = true,
    this.tapToFocus = true,
    this.pinchToZoom = true,
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
    this.showTrackingBoxes = false,
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
    this.showZoomSlider = false,
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

  /// Called with the raw value of the first symbol in each detection.
  final ValueChanged<String>? onScan;

  /// Called with every symbol in each detection, with geometry and metadata.
  final ValueChanged<List<UCode>>? onCodes;
  final void Function(Object error, StackTrace stackTrace)? onScanError;

  /// External controller. When given, the session options below are ignored.
  final UCameraController? controller;

  final bool autoStart;
  final UCameraFacing facing;
  final UCameraResolution resolution;
  final UCameraLens? lensType;
  final UScanSpeed speed;
  final Duration dedupeWindow;

  /// Empty means every supported symbology. Restricting this is the single
  /// biggest speed win available.
  final List<UCodeFormat> formats;
  final UScanEngine engine;
  final bool torchEnabled;

  /// Also try the inverted image, for light-on-dark symbols.
  final bool tryInvert;
  final bool autoZoom;
  final double? initialZoom;

  final BoxFit fit;
  final Widget Function(BuildContext context, UCameraException error)? errorBuilder;
  final WidgetBuilder? placeholderBuilder;
  final LayoutWidgetBuilder? overlayBuilder;

  /// Explicit detection window in widget coordinates. Overrides
  /// [restrictToScanWindow] plus [scanWindowSize].
  final Rect? scanWindow;
  final bool restrictToScanWindow;
  final bool useAppLifecycleState;
  final bool tapToFocus;
  final bool pinchToZoom;

  /// Stop reporting after the first successful scan.
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

  /// Draws a live box around each detected symbol.
  final bool showTrackingBoxes;

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
  final bool showZoomSlider;
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

class _UScannerState extends State<UScanner> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  UCameraController? _controller;
  late bool _ownsController;
  AnimationController? _lineController;
  StreamSubscription<List<UCode>>? _codes;
  List<UCode> _tracked = const <UCode>[];
  bool _handled = false;
  double _baseZoom = 1;
  UCameraException? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showScanLine) {
      _lineController = AnimationController(vsync: this, duration: widget.scanLineDuration)..repeat(reverse: true);
    }
    _ownsController = widget.controller == null;
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lineController?.dispose();
    unawaited(_codes?.cancel());
    if (_ownsController) unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.useAppLifecycleState) return;
    final UCameraController? controller = _controller;
    if (controller == null || !_ownsController) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(controller.suspend());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(controller.resume());
    }
  }

  Future<void> _bootstrap() async {
    UCameraController? controller = widget.controller;
    if (controller == null) {
      final UCameraPermissionState permission = await UCameraController.requestPermission();
      if (!permission.isGranted) {
        if (mounted) setState(() => _error = const UCameraException(code: UCameraErrorCode.permission, message: "Camera permission denied"));
        return;
      }
      controller = UCameraController(
        config: UCameraConfig(
          facing: widget.facing,
          lens: widget.lensType,
          resolution: widget.resolution,
          enableAudio: false,
          flash: widget.torchEnabled ? UFlashMode.torch : UFlashMode.off,
          initialZoom: widget.initialZoom,
          scanning: widget.autoStart,
          scanEngine: widget.engine,
          scanOptions: UCodeScanOptions(formats: widget.formats, multiple: !widget.singleScan, tryInvert: widget.tryInvert),
          scanInterval: widget.speed.interval,
          scanDedupeWindow: widget.dedupeWindow,
          frameMaxFps: widget.speed.maxFps,
        ),
      );
      await controller.initialize();
    } else if (widget.autoStart && !controller.value.isScanning) {
      await controller.startScanning();
    }

    if (!mounted) {
      if (_ownsController) await controller.dispose();
      return;
    }
    _codes = controller.codes.listen(_onCodes, onError: (Object error, StackTrace stackTrace) => widget.onScanError?.call(error, stackTrace));
    setState(() {
      _controller = controller;
      _error = controller!.value.error;
    });
  }

  void _onCodes(List<UCode> codes) {
    if (codes.isEmpty) return;
    if (widget.singleScan && _handled) return;
    if (widget.showTrackingBoxes && mounted) setState(() => _tracked = codes);
    widget.onCodes?.call(codes);
    final String text = codes.first.text;
    if (text.isEmpty) return;
    if (widget.singleScan) _handled = true;
    if (widget.hapticOnScan) unawaited(HapticFeedback.mediumImpact());
    widget.onScan?.call(text);
  }

  Future<void> _scanFromGallery() async {
    final List<FileData> files = await UFile.showImagePicker(source: UImageSource.gallery);
    if (files.isEmpty) return;
    final List<UCode> codes = await UCameraController.analyzeImage(
      path: files.first.path,
      bytes: files.first.bytes,
      options: UCodeScanOptions(formats: widget.formats, multiple: !widget.singleScan, tryInvert: true),
      engine: widget.engine,
    );
    if (codes.isEmpty) {
      UToast.warning(message: U.s.noBarcodeWasFoundInTheImage);
      return;
    }
    _onCodes(codes);
  }

  /// Clears the single-scan latch so the same code can fire again.
  void resume() {
    _handled = false;
    _controller?.resetScanHistory();
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

  Widget _buildControls(UCameraController controller, UCameraValue value) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: widget.controlsSpacing,
    children: <Widget>[
      if (widget.showGalleryButton) _controlButton(icon: widget.galleryIcon, tooltip: U.s.scanFromGallery, onTap: () => unawaited(_scanFromGallery())),
      if (widget.showTorchButton && value.capabilities.torch)
        _controlButton(
          icon: value.torchOn ? widget.torchOnIcon : widget.torchOffIcon,
          tooltip: U.s.flashlight,
          color: value.torchOn ? (widget.controlActiveIconColor ?? Theme.of(context).colorScheme.primary) : null,
          onTap: () => unawaited(controller.toggleTorch()),
        ),
      if (widget.showSwitchCameraButton) _controlButton(icon: widget.switchCameraIcon, tooltip: U.s.switchCamera, onTap: () => unawaited(controller.switchCamera())),
    ],
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
  Widget build(BuildContext context) {
    final UCameraException? error = _error;
    if (error != null) {
      return widget.errorBuilder?.call(context, error) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.no_photography_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(error.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  UButton(title: U.s.retry, onTap: () => unawaited(_bootstrap())),
                ],
              ),
            ),
          );
    }

    final UCameraController? controller = _controller;
    if (controller == null) {
      return widget.placeholderBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<UCameraValue>(
      valueListenable: controller,
      builder: (BuildContext context, UCameraValue value, Widget? _) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size bounds = Size(constraints.maxWidth, constraints.maxHeight);
          final Rect window =
              widget.scanWindow ??
              Rect.fromCenter(
                center: Offset(bounds.width / 2, bounds.height / 2),
                width: widget.scanWindowSize.width,
                height: widget.scanWindowSize.height,
              );
          if (widget.restrictToScanWindow || widget.scanWindow != null) {
            controller.setScanRegion(
              Rect.fromLTWH(window.left / bounds.width, window.top / bounds.height, window.width / bounds.width, window.height / bounds.height),
            );
          }
          final Color borderColor = widget.borderColor ?? Theme.of(context).colorScheme.primary;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: widget.pinchToZoom ? (ScaleStartDetails _) => _baseZoom = value.zoom : null,
                onScaleUpdate: widget.pinchToZoom
                    ? (ScaleUpdateDetails details) {
                        if (details.pointerCount == 2) unawaited(controller.setZoom(_baseZoom * details.scale));
                      }
                    : null,
                onTapUp: widget.tapToFocus
                    ? (TapUpDetails details) => unawaited(
                        controller.focusAndMeterAt(
                          UCameraUtils.normalizePoint(
                            local: details.localPosition,
                            widgetSize: bounds,
                            previewSize: value.previewSize,
                            fit: widget.fit,
                            mirrored: value.mirrored,
                          ),
                        ),
                      )
                    : null,
                child: UCameraPreview(controller: controller, fit: widget.fit, placeholder: widget.placeholderBuilder?.call(context)),
              ),
              if (widget.showOverlay && widget.overlayBuilder == null)
                CustomPaint(
                  size: bounds,
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
              if (widget.showTrackingBoxes && _tracked.isNotEmpty)
                CustomPaint(
                  size: bounds,
                  painter: _UCodeTrackingPainter(
                    codes: _tracked,
                    color: borderColor,
                    previewSize: value.previewSize,
                    widgetSize: bounds,
                    fit: widget.fit,
                    mirrored: value.mirrored,
                  ),
                ),
              if (widget.overlayBuilder != null) widget.overlayBuilder!(context, constraints),
              if (widget.showScanLine && _lineController != null)
                AnimatedBuilder(
                  animation: _lineController!,
                  builder: (BuildContext context, Widget? _) {
                    final double y = window.top + widget.borderWidth + (window.height - 2 * widget.borderWidth) * _lineController!.value;
                    return Positioned(
                      left: window.left + widget.borderWidth,
                      top: y,
                      width: window.width - 2 * widget.borderWidth,
                      height: widget.scanLineThickness,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.scanLineColor ?? borderColor,
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: (widget.scanLineColor ?? borderColor).withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1),
                          ],
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
                  bottom: widget.hintPosition == UScannerHintPosition.bottom ? bounds.height - window.bottom - widget.hintGap - 44 : null,
                  child: Align(child: _buildHint()),
                ),
              if (widget.showZoomSlider && !value.capabilities.zoom.isFixed)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: widget.controlsPadding.bottom + widget.controlButtonSize + 16,
                  child: Slider(
                    value: value.capabilities.zoom.clamp(value.zoom),
                    min: value.capabilities.zoom.min,
                    max: value.capabilities.zoom.max,
                    onChanged: (double next) => unawaited(controller.setZoom(next)),
                  ),
                ),
              if (widget.showControls)
                Align(
                  alignment: widget.controlsAlignment,
                  child: Padding(padding: widget.controlsPadding, child: _buildControls(controller, value)),
                ),
            ],
          );
        },
      ),
    );
  }
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
      ..moveTo(window.left, window.top + r + l)
      ..lineTo(window.left, window.top + r)
      ..arcToPoint(Offset(window.left + r, window.top), radius: Radius.circular(r))
      ..lineTo(window.left + r + l, window.top)
      ..moveTo(window.right - r - l, window.top)
      ..lineTo(window.right - r, window.top)
      ..arcToPoint(Offset(window.right, window.top + r), radius: Radius.circular(r))
      ..lineTo(window.right, window.top + r + l)
      ..moveTo(window.right, window.bottom - r - l)
      ..lineTo(window.right, window.bottom - r)
      ..arcToPoint(Offset(window.right - r, window.bottom), radius: Radius.circular(r))
      ..lineTo(window.right - r - l, window.bottom)
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

/// Draws a live outline around each detected symbol.
class _UCodeTrackingPainter extends CustomPainter {
  _UCodeTrackingPainter({
    required this.codes,
    required this.color,
    required this.previewSize,
    required this.widgetSize,
    required this.fit,
    required this.mirrored,
  });

  final List<UCode> codes;
  final Color color;
  final UCameraSize previewSize;
  final Size widgetSize;
  final BoxFit fit;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    if (previewSize.width == 0) return;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    for (final UCode code in codes) {
      if (code.corners.isEmpty) continue;
      final Path path = Path();
      for (int i = 0; i < code.corners.length; i++) {
        final Offset point = UCameraUtils.denormalizePoint(
          normalized: Offset(code.corners[i].dx / previewSize.width, code.corners[i].dy / previewSize.height),
          widgetSize: widgetSize,
          previewSize: previewSize,
          fit: fit,
          mirrored: mirrored,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_UCodeTrackingPainter oldDelegate) => oldDelegate.codes != codes;
}

/// A ready-to-use full-screen scanner page wrapping [UScanner].
///
/// By default it pops with the scanned string, so it can be awaited with
/// [UScannerPage.open].
class UScannerPage extends StatelessWidget {
  const UScannerPage({
    this.title,
    this.appBar,
    this.showAppBar = true,
    this.backgroundColor,
    this.autoPopOnScan = true,
    this.onScan,
    this.onCodes,
    this.onScanError,
    this.controller,
    this.autoStart = true,
    this.facing = UCameraFacing.back,
    this.resolution = UCameraResolution.high,
    this.speed = UScanSpeed.normal,
    this.formats = const <UCodeFormat>[],
    this.engine = UScanEngine.auto,
    this.torchEnabled = false,
    this.tryInvert = false,
    this.initialZoom,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholderBuilder,
    this.overlayBuilder,
    this.scanWindow,
    this.restrictToScanWindow = true,
    this.useAppLifecycleState = true,
    this.tapToFocus = true,
    this.pinchToZoom = true,
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
    this.showTrackingBoxes = false,
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
    this.showZoomSlider = false,
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

  /// Pushes this page and awaits the scanned string, or null if dismissed.
  static Future<String?> open({
    String? title,
    List<UCodeFormat> formats = const <UCodeFormat>[],
    String? hintText,
    bool showGalleryButton = false,
    UScanSpeed speed = UScanSpeed.normal,
  }) => UNavigator.push<String>(UScannerPage(title: title, formats: formats, hintText: hintText, showGalleryButton: showGalleryButton, speed: speed));

  /// Pushes this page and awaits the full result, with format and geometry.
  static Future<UCode?> openForCode({String? title, List<UCodeFormat> formats = const <UCodeFormat>[], String? hintText}) async {
    UCode? scanned;
    await UNavigator.push<String>(
      UScannerPage(
        title: title,
        formats: formats,
        hintText: hintText,
        onCodes: (List<UCode> codes) => scanned = codes.isEmpty ? null : codes.first,
      ),
    );
    return scanned;
  }

  final String? title;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool autoPopOnScan;

  final ValueChanged<String>? onScan;
  final ValueChanged<List<UCode>>? onCodes;
  final void Function(Object error, StackTrace stackTrace)? onScanError;
  final UCameraController? controller;
  final bool autoStart;
  final UCameraFacing facing;
  final UCameraResolution resolution;
  final UScanSpeed speed;
  final List<UCodeFormat> formats;
  final UScanEngine engine;
  final bool torchEnabled;
  final bool tryInvert;
  final double? initialZoom;
  final BoxFit fit;
  final Widget Function(BuildContext context, UCameraException error)? errorBuilder;
  final WidgetBuilder? placeholderBuilder;
  final LayoutWidgetBuilder? overlayBuilder;
  final Rect? scanWindow;
  final bool restrictToScanWindow;
  final bool useAppLifecycleState;
  final bool tapToFocus;
  final bool pinchToZoom;
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
  final bool showTrackingBoxes;
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
  final bool showZoomSlider;
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
    appBar: showAppBar
        ? (appBar ??
              AppBar(
                title: Text(title ?? U.s.scanBarcode),
                backgroundColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0),
                elevation: 0,
              ))
        : null,
    body: UScanner(
      onScan: (String value) {
        onScan?.call(value);
        if (autoPopOnScan) UNavigator.back<String>(value);
      },
      onCodes: onCodes,
      onScanError: onScanError,
      controller: controller,
      autoStart: autoStart,
      facing: facing,
      resolution: resolution,
      speed: speed,
      formats: formats,
      engine: engine,
      torchEnabled: torchEnabled,
      tryInvert: tryInvert,
      initialZoom: initialZoom,
      fit: fit,
      errorBuilder: errorBuilder,
      placeholderBuilder: placeholderBuilder,
      overlayBuilder: overlayBuilder,
      scanWindow: scanWindow,
      restrictToScanWindow: restrictToScanWindow,
      useAppLifecycleState: useAppLifecycleState,
      tapToFocus: tapToFocus,
      pinchToZoom: pinchToZoom,
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
      showTrackingBoxes: showTrackingBoxes,
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
      showZoomSlider: showZoomSlider,
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
