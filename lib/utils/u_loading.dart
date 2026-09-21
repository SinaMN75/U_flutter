import "dart:ui";

import "package:u/utilities.dart";

typedef ULoadingPercentBuilder = Widget Function(BuildContext context, int percent);

class ULoadingSettings {
  const ULoadingSettings({
    this.builder,
    this.source,
    this.package,
    this.fileData,
    this.imageWidth = 80,
    this.imageHeight = 80,
    this.imageFit = BoxFit.contain,
    this.imageColor,
    this.imageBorderRadius = 0,
    this.imagePlaceholder,
    this.overlayColor = Colors.black54,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.blurAmount = 2,
    this.dismissible = false,
    this.useDefaultLoader = true,
    this.text,
    this.textColor = Colors.white,
    this.spinnerColor = Colors.white,
    this.spinnerSize = 40,
    this.spinnerStrokeWidth = 3,
    this.useProgressIndicator = false,
    this.spacing = 16,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.showPercent = true,
    this.percentSuffix = "%",
    this.percentTextColor,
    this.percentBuilder,
    this.onDismiss,
  });

  final WidgetBuilder? builder;
  final String? source;
  final String? package;
  final UFileData? fileData;
  final double imageWidth;
  final double imageHeight;
  final BoxFit imageFit;
  final Color? imageColor;
  final double imageBorderRadius;
  final String? imagePlaceholder;
  final Color overlayColor;
  final Duration animationDuration;
  final Curve animationCurve;
  final double blurAmount;
  final bool dismissible;
  final bool useDefaultLoader;
  final String? text;
  final Color textColor;
  final Color spinnerColor;
  final double spinnerSize;
  final double spinnerStrokeWidth;
  final bool useProgressIndicator;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final AlignmentGeometry alignment;
  final bool showPercent;
  final String percentSuffix;
  final Color? percentTextColor;
  final ULoadingPercentBuilder? percentBuilder;
  final VoidCallback? onDismiss;

  ULoadingSettings copyWith({
    WidgetBuilder? builder,
    String? source,
    String? package,
    UFileData? fileData,
    double? imageWidth,
    double? imageHeight,
    BoxFit? imageFit,
    Color? imageColor,
    double? imageBorderRadius,
    String? imagePlaceholder,
    Color? overlayColor,
    Duration? animationDuration,
    Curve? animationCurve,
    double? blurAmount,
    bool? dismissible,
    bool? useDefaultLoader,
    String? text,
    Color? textColor,
    Color? spinnerColor,
    double? spinnerSize,
    double? spinnerStrokeWidth,
    bool? useProgressIndicator,
    double? spacing,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? borderRadius,
    AlignmentGeometry? alignment,
    bool? showPercent,
    String? percentSuffix,
    Color? percentTextColor,
    ULoadingPercentBuilder? percentBuilder,
    VoidCallback? onDismiss,
  }) => ULoadingSettings(
    builder: builder ?? this.builder,
    source: source ?? this.source,
    package: package ?? this.package,
    fileData: fileData ?? this.fileData,
    imageWidth: imageWidth ?? this.imageWidth,
    imageHeight: imageHeight ?? this.imageHeight,
    imageFit: imageFit ?? this.imageFit,
    imageColor: imageColor ?? this.imageColor,
    imageBorderRadius: imageBorderRadius ?? this.imageBorderRadius,
    imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
    overlayColor: overlayColor ?? this.overlayColor,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    blurAmount: blurAmount ?? this.blurAmount,
    dismissible: dismissible ?? this.dismissible,
    useDefaultLoader: useDefaultLoader ?? this.useDefaultLoader,
    text: text ?? this.text,
    textColor: textColor ?? this.textColor,
    spinnerColor: spinnerColor ?? this.spinnerColor,
    spinnerSize: spinnerSize ?? this.spinnerSize,
    spinnerStrokeWidth: spinnerStrokeWidth ?? this.spinnerStrokeWidth,
    useProgressIndicator: useProgressIndicator ?? this.useProgressIndicator,
    spacing: spacing ?? this.spacing,
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    alignment: alignment ?? this.alignment,
    showPercent: showPercent ?? this.showPercent,
    percentSuffix: percentSuffix ?? this.percentSuffix,
    percentTextColor: percentTextColor ?? this.percentTextColor,
    percentBuilder: percentBuilder ?? this.percentBuilder,
    onDismiss: onDismiss ?? this.onDismiss,
  );
}

class ULoading {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;
  static ULoadingSettings _settings = const ULoadingSettings();
  static ULoadingSettings _activeSettings = const ULoadingSettings();
  static final URxnInt _percent = URxnInt();
  static URxInt? _boundPercent;

  static ULoadingSettings get settings => _settings;

  static int? get percent => _percent.value;

  static void initialize({ULoadingSettings? settings, GlobalKey<NavigatorState>? key}) {
    if (settings != null) {
      _settings = settings;
      _activeSettings = settings;
    }
    if (key != null) navigatorKey = key;
  }

  static void show({
    BuildContext? context,
    ULoadingSettings? settings,
    WidgetBuilder? customLoader,
    String? text,
    String? source,
    String? package,
    int? percent,
    URxInt? percentRx,
  }) {
    if (_isShowing) {
      update(
        settings: settings,
        customLoader: customLoader,
        text: text,
        source: source,
        package: package,
        percent: percent,
        percentRx: percentRx,
      );
      return;
    }
    final OverlayState? overlayState = context != null ? Overlay.of(context) : navigatorKey.currentState?.overlay;
    if (overlayState == null) return;
    _activeSettings = (settings ?? _settings).copyWith(builder: customLoader, text: text, source: source, package: package);
    setPercent(null);
    _bindPercent(percent: percent, percentRx: percentRx);
    _overlayEntry = OverlayEntry(builder: (BuildContext _) => _LoadingOverlay(settings: _activeSettings));
    overlayState.insert(_overlayEntry!);
    _isShowing = true;
  }

  static void update({
    ULoadingSettings? settings,
    WidgetBuilder? customLoader,
    String? text,
    String? source,
    String? package,
    int? percent,
    URxInt? percentRx,
  }) {
    if (!_isShowing) return;
    if (settings != null || customLoader != null || text != null || source != null || package != null) {
      _activeSettings = (settings ?? _activeSettings).copyWith(builder: customLoader, text: text, source: source, package: package);
      _overlayEntry?.markNeedsBuild();
    }
    if (percent != null || percentRx != null) _bindPercent(percent: percent, percentRx: percentRx);
  }

  static void setPercent(int? percent) {
    _unbindPercent();
    _percent.value = percent?.clamp(0, 100);
  }

  static void dismiss() {
    if (!_isShowing) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
    _unbindPercent();
    _percent.value = null;
    _activeSettings.onDismiss?.call();
    _activeSettings = _settings;
  }

  static bool isShowing() => _isShowing;

  static void _bindPercent({int? percent, URxInt? percentRx}) {
    if (percentRx != null) {
      if (_boundPercent != percentRx) {
        _unbindPercent();
        _boundPercent = percentRx..addListener(_onBoundPercentChanged);
      }
      _onBoundPercentChanged();
      return;
    }
    if (percent != null) setPercent(percent);
  }

  static void _unbindPercent() {
    _boundPercent?.removeListener(_onBoundPercentChanged);
    _boundPercent = null;
  }

  static void _onBoundPercentChanged() => _percent.value = _boundPercent?.value.clamp(0, 100);
}

class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay({required this.settings});

  final ULoadingSettings settings;

  @override
  State<_LoadingOverlay> createState() => __LoadingOverlayState();
}

class __LoadingOverlayState extends State<_LoadingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.settings.animationDuration, vsync: this);
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.settings.animationCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacityAnimation,
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.settings.blurAmount, sigmaY: widget.settings.blurAmount),
            child: UContainer(color: widget.settings.overlayColor),
          ),
        ),
        if (widget.settings.dismissible)
          const Positioned.fill(
            child: UContainer(
              onTap: ULoading.dismiss,
              hitTestBehavior: HitTestBehavior.opaque,
              color: Colors.transparent,
            ),
          ),
        Align(
          alignment: widget.settings.alignment,
          child: widget.settings.builder != null
              ? widget.settings.builder!(context)
              : widget.settings.useDefaultLoader
              ? _buildDefaultLoader(context)
              : const SizedBox(),
        ),
      ],
    ),
  );

  Widget _buildDefaultLoader(BuildContext context) => UObx(() {
    final ULoadingSettings settings = widget.settings;
    final int? percent = ULoading._percent.value;
    final String text = settings.text ?? U.s.loading;
    return UContainer(
      color: settings.backgroundColor,
      radius: settings.borderRadius,
      padding: settings.padding,
      margin: settings.margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildIndicator(settings, percent),
          if (text.isNotEmpty) ...<Widget>[
            SizedBox(height: settings.spacing),
            UTextBodyLarge(text, color: settings.textColor),
          ],
          if (percent != null && settings.showPercent) ...<Widget>[
            SizedBox(height: settings.spacing / 2),
            if (settings.percentBuilder != null)
              settings.percentBuilder!(context, percent)
            else
              UTextTitleMedium("$percent${settings.percentSuffix}", color: settings.percentTextColor ?? settings.textColor),
          ],
        ],
      ),
    );
  });

  Widget _buildIndicator(ULoadingSettings settings, int? percent) {
    final bool hasSource = settings.source?.isNotEmpty ?? false;
    if (settings.fileData != null || hasSource) {
      return UImage(
        settings.source ?? "",
        fileData: settings.fileData,
        package: settings.package,
        width: settings.imageWidth,
        height: settings.imageHeight,
        fit: settings.imageFit,
        color: settings.imageColor,
        borderRadius: settings.imageBorderRadius,
        placeholder: settings.imagePlaceholder,
      );
    }
    if (settings.useProgressIndicator) {
      return UProgressCircular(
        value: percent,
        size: settings.spinnerSize,
        strokeWidth: settings.spinnerStrokeWidth,
        progressColor: settings.spinnerColor,
      );
    }
    return SizedBox(
      width: settings.spinnerSize,
      height: settings.spinnerSize,
      child: CircularProgressIndicator(
        value: percent == null ? null : percent / 100,
        valueColor: AlwaysStoppedAnimation<Color>(settings.spinnerColor),
        strokeWidth: settings.spinnerStrokeWidth,
      ),
    );
  }
}
